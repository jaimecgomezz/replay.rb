require_relative 'context/sequencer'
require_relative 'context/requester'

module Replay
  class Context
    include Sequencer
    include Requester

    def initialize(state = {}, actions = {}, sequences = {})
      @__replay_state = state || {}
      @__replay_sequences = sequences || {}

      # Run user-provided initialization mechanism
      initialization = actions.delete(:initialization)

      # Dynamically define user-provided actions as instance methods
      actions.each do |action, blk|
        define_singleton_method(action) do |argument = nil, &handler|
          argument = nil if argument.is_a?(Replay::Context)

          result = instance_exec(argument, &blk)

          return result if handler.nil?

          handler.call(result)
        rescue LocalJumpError => e
          e.exit_value
        end
      end

      state.nil? ? instance_eval(&initialization) : instance_exec(state, &initialization)
    end

    def get(field)
      @__replay_state[field]
    end

    def set(field, value)
      @__replay_state[field] = value
    end
  end
end

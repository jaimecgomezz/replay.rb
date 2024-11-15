module Replay
  class Context
    def initialize(state = {}, actions = {})
      @__replay_state = state || {}

      # Run user-provided initialization mechanism
      initialization = actions.delete(:initialization)

      # Dynamically define user-provided actions as instance methods
      actions.each do |action, blk|
        define_singleton_method(action) do |argument = nil|
          argument.nil? ? instance_eval(&blk) : instance_exec(argument, &blk)
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

    def request(method, uri, options = {})
      raise(ArgumentError, "Invalid HTTP method: #{method}") unless HTTParty.respond_to?(method)

      response = HTTParty.send(method, uri, options)

      return response unless block_given?

      yield(response)
    end
  end
end

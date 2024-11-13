module Replay
  module Scenario
    def self.extended(base)
      base.instance_variable_set(
        :@_state,
        { scenario_started: false, non_started_scenario_alerted: false }
      )

      base.instance_variable_set(
        :@_actions,
        Hash.new do |hash, key|
          puts("WARN: No '#{key}' action defined, defaulting to a noop code block")
          hash[key] = ->(*) {}
        end
      )

      base.include(SceneMethods(base))
    end

    def self.SceneMethods(base)
      Module.new.module_exec(base) do |base|
        define_method(:start) do |argument = nil|
          run(:start, argument).tap do
            set(:scenario_started, true)
          end
        end

        define_method(:get) do |key|
          base.instance_variable_get(:@_state)[key]
        end

        define_method(:set) do |key, value|
          base.instance_variable_get(:@_state)[key] = value
        end

        define_method(:run) do |action, argument = nil|
          if action != :start && !get(:scenario_started) && !get(:non_started_scenario_alerted)
            name = base.name.split('::').last
            puts("WARN: '#{name}' Scenario hasn't been started yet. Unexecpected behavior may emerge.")
            set(:non_started_scenario_alerted, true)
          end

          base.instance_variable_get(:@_actions)[action].call(argument)
        end

        self
      end
    end

    def on_start(defaults = nil, &blk)
      return unless block_given?

      @_actions[:start] = lambda do |argument = nil|
        blk.call(argument || defaults)
      end
    end

    def on_action(action, defaults = nil, &blk)
      return unless block_given?

      @_actions[action.to_sym] = lambda do |argument = nil|
        blk.call(argument || defaults)
      end
    end
  end
end

module Replay
  class Context
    def initialize(scenario)
      @__replay_state = {}

      # Define the configuration mechanism
      __define_configure_method(
        scenario,
        scenario::REPLAY_ACTIONS.delete(:configure)
      )

      # Dynamically define user-provided actions as instance methods
      scenario::REPLAY_ACTIONS.each do |name, info|
        __define_action_method(scenario, name, info)
      end

      scenario::REPLAY_SEQUENCES.each do |name, info|
        __define_sequence_method(scenario, name, info)
      end

      scenario::REPLAY_INCLUSIONS.each do |subcontext|
        singleton_class.include(subcontext)
      end

      scenario::REPLAY_EXTENSIONS.each do |subcontext|
        singleton_class.extend(subcontext)
      end
    end

    # State management methods
    def get(field)
      @__replay_state[field]
    end

    def set(field, value)
      @__replay_state[field] = value
    end

    # Request methods
    def http(method, uri, options = {})
      raise(ArgumentError, "Invalid HTTP method: #{method}") unless HTTParty.respond_to?(method)

      # options = options.merge({ debug_output: $stdout })
      response = HTTParty.send(method, uri, options)

      return response unless block_given?

      yield(response)
    end

    private

    def __define_configure_method(scenario, info)
      if info.nil?
        @__replay_configured = true
        define_singleton_method(:configure) {}
        return
      end

      @__replay_configured = false
      default, blk = info.values_at(:default, :blk)
      _requireness, parameter = blk.parameters.first || []

      define_singleton_method(:configure) do |argument = default, &handler|
        argument = default if argument.nil?

        raise(ArgumentError, "Expected '#{parameter}' on 'configure' action from #{scenario}, got: nil") if argument.nil? && !parameter.nil?

        @__replay_configured = true

        result = instance_exec(argument, &blk)

        return result if handler.nil?

        handler.call(result)
      rescue LocalJumpError => e
        e.exit_value
      end
    end

    def __define_action_method(scenario, name, info)
      default, blk = info.values_at(:default, :blk)
      _requireness, parameter = blk.parameters.first || []

      define_singleton_method(name) do |argument = default, &handler|
        raise("#{scenario} hasn't been configured yet, call .configure") unless @__replay_configured

        argument = default if argument.nil?

        raise(ArgumentError, "Expected '#{parameter}' on '#{name}' action from #{scenario}, got nil") if argument.nil? && !parameter.nil?

        result = instance_exec(argument, &blk)

        return result if handler.nil?

        handler.call(result)
      rescue LocalJumpError => e
        e.exit_value
      end
    end

    def __define_sequence_method(scenario, name, info)
      defaults, blk = info.values_at(:defaults, :blk)

      define_singleton_method(name) do |items = defaults|
        sequence = instance_variable_get("@#{name}")

        return sequence unless sequence.nil?

        items = defaults if items.nil?

        raise(ArgumentError, "Expected an Iterable on '#{name}' sequence from #{scenario}, got: #{items}") unless items.is_a?(Iterable)

        instance_variable_set("@#{name}", Replay::Sequence.new(self, name, items, blk))
      end
    end
  end
end

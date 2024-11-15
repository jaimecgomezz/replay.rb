require_relative 'replay/version'
require_relative 'replay/httparty'
require_relative 'replay/context'

module Replay
  def self.included(includer)
    case includer
    when Class
      typerr!(includer)
    when Module
      includer.const_set(:REPLAY_ACTIONS, { initialization: ->(*) {} }) unless includer.const_defined?(:REPLAY_ACTIONS)
      includer.const_set(:REPLAY_INCLUSIONS, []) unless includer.const_defined?(:REPLAY_INCLUSIONS)
      includer.const_set(:REPLAY_EXTENSIONS, []) unless includer.const_defined?(:REPLAY_EXTENSIONS)
      includer.extend(ReplayDefinitionMethods)
      abstract_include(includer)
    else
      typerr!(includer)
    end
  end

  def self.abstract_include(abstract_includer)
    abstract_includer.extend(abstract_includer)

    abstract_includer.module_eval do
      abstract_includer_wrapper = Module.new do
        define_method abstract_includer.__context_name do
          abstract_includer.__context_instance
        end
      end

      define_singleton_method(:included) do |concrete_includer|
        concrete_includer.const_set(:REPLAY_INCLUSIONS, []) unless concrete_includer.const_defined?(:REPLAY_INCLUSIONS)
        concrete_includer::REPLAY_INCLUSIONS << abstract_includer_wrapper
        concrete_includer.send(:include, abstract_includer_wrapper)
      end

      define_singleton_method(:extended) do |concrete_extender|
        concrete_extender.const_set(:REPLAY_EXTENSIONS, []) unless concrete_extender.const_defined?(:REPLAY_EXTENSIONS)
        concrete_extender::REPLAY_EXTENSIONS << abstract_includer_wrapper
        concrete_extender.send(:extend, abstract_includer_wrapper)
      end
    end
  end

  def self.typerr!(klass)
    raise(ArgumentError, "Can't make '#{klass.name}' a registry, expected a Module")
  end

  module ReplayDefinitionMethods
    def on_start(default = nil, &blk)
      raise(ArgumentError, "Hash must be provided to #on_start method: #{default}") unless default.is_a?(Hash)

      self::REPLAY_ACTIONS[:initialization] = lambda do |argument = default|
        argument = default if argument.is_a?(Replay::Context)
        argument.nil? ? instance_eval(&blk) : instance_exec(argument, &blk)
      end
    end

    def action(name, default = nil, &blk)
      self::REPLAY_ACTIONS[name.to_sym] = lambda do |argument = default|
        argument = default if argument.is_a?(Replay::Context)
        argument.nil? ? instance_eval(&blk) : instance_exec(argument, &blk)
      end
    end

    def start(state = nil)
      prompt = Pry::Prompt.new(
        'replay',
        'replay custom prompt',
        [proc { "replay(#{__context_name})> " }]
      )

      Pry.start(__context_instance(state), prompt: prompt)
    end

    def __context_name
      name
        .split('::')
        .last
        .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
        .gsub(/([a-z\d])([A-Z])/, '\1_\2')
        .tr('-', '_')
        .gsub(/\s/, '_')
        .gsub(/__+/, '_')
        .downcase
    end

    def __context_instance(state = nil)
      @__context_instance ||= Replay::Context.new(state, self::REPLAY_ACTIONS).tap do |context|
        context.instance_exec(self::REPLAY_INCLUSIONS) do |subcontexts|
          subcontexts.each do |subcontext|
            singleton_class.include(subcontext)
          end
        end

        context.instance_exec(self::REPLAY_EXTENSIONS) do |subcontexts|
          subcontexts.each do |subcontext|
            singleton_class.extend(subcontext)
          end
        end
      end
    end
  end
end

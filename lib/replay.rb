require 'pry'
require 'httparty'

require_relative 'replay/version'
require_relative 'replay/sequence'
require_relative 'replay/context'

module Replay
  def self.included(scenario)
    case scenario
    when Class
      raise(ArgumentError, "Replay should only be included in modules: #{klass}")
    when Module
      scenario.const_set(:REPLAY_ACTIONS, {}) unless scenario.const_defined?(:REPLAY_ACTIONS)
      scenario.const_set(:REPLAY_SEQUENCES, {}) unless scenario.const_defined?(:REPLAY_SEQUENCES)
      scenario.const_set(:REPLAY_INCLUSIONS, []) unless scenario.const_defined?(:REPLAY_INCLUSIONS)
      scenario.const_set(:REPLAY_EXTENSIONS, []) unless scenario.const_defined?(:REPLAY_EXTENSIONS)
      scenario.const_set(:REPLAY_SCENARIO_NAME, scenario.name.split('::').last.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').gsub(/([a-z\d])([A-Z])/, '\1_\2').tr('-', '_').gsub(/\s/, '_').gsub(/__+/, '_').downcase) # rubocop:disable Layout/LineLength
      scenario.extend(ReplayDefinitionMethods)
      abstract_include(scenario)
    end
  end

  def self.abstract_include(scenario)
    scenario.extend(scenario)

    scenario.module_eval do
      scenario_wrapper = Module.new do
        define_method scenario::REPLAY_SCENARIO_NAME do
          scenario.__replay_context
        end
      end

      define_singleton_method(:included) do |scenario_includer|
        scenario_includer.const_set(:REPLAY_INCLUSIONS, []) unless scenario_includer.const_defined?(:REPLAY_INCLUSIONS)
        scenario_includer::REPLAY_INCLUSIONS << scenario_wrapper
        scenario_includer.send(:include, scenario_wrapper)
      end

      define_singleton_method(:extended) do |scenario_extender|
        scenario_extender.const_set(:REPLAY_EXTENSIONS, []) unless scenario_extender.const_defined?(:REPLAY_EXTENSIONS)
        scenario_extender::REPLAY_EXTENSIONS << scenario_wrapper
        scenario_extender.send(:extend, scenario_wrapper)
      end
    end
  end

  module ReplayDefinitionMethods
    def configuration(default = nil, &blk)
      self::REPLAY_ACTIONS[:configure] = { default: default, blk: blk }
    end

    def action(name, default = nil, &blk)
      self::REPLAY_ACTIONS[name.to_sym] = { default: default, blk: blk }
    end

    def sequence(name, defaults = nil, &blk)
      self::REPLAY_SEQUENCES[name.to_sym] = { defaults: defaults, blk: blk }
    end

    def start(argument = nil)
      context = Replay::Context.new(self).tap do |ctx|
        ctx.configure(argument)
      end

      Pry.start(context, prompt: Pry::Prompt.new('replay', 'replay custom prompt', [proc { "replay(#{self::REPLAY_SCENARIO_NAME})> " }]))
    end

    def __replay_context
      @__replay_context ||= Replay::Context.new(self)
    end
  end
end

module Replay
  class Sequence
    attr_reader :context, :scenario, :defaults, :identifier, :items, :index, :blk

    def initialize(context, scenario, defaults, identifier, blk)
      @context = context
      @scenario = scenario
      @defaults = defaults
      @identifier = identifier
      @index = 0
      @blk = blk
    end

    def set(items = defaults)
      raise(ArgumentError, "Expected an Enumerable as '#{identifier}' items, got: nil") if items.nil?
      raise(ArgumentError, "Expected an Enumerable as '#{identifier}' items, got: #{items}") unless items.is_a?(Enumerable)

      @index = 0
      @items = items
    end

    def fw(steps = 1)
      return if steps <= 0

      @items ||= defaults

      raise("No sequence of items found for '#{identifier}' sequece, run #set first") if items.nil?

      results = steps.times.map { __fw }

      steps == 1 ? results.first : results
    end

    def bw(steps = 1)
      return if steps <= 0

      @items ||= defaults

      raise("No sequence of items found for '#{identifier}' sequece, run #set first") if items.nil?

      results = steps.times.map { __bw }

      steps == 1 ? results.first : results
    end

    def rw
      @items ||= defaults

      raise("No sequence of items found for '#{identifier}' sequece, run #set first") if items.nil?

      (@index + 1).tap do
        @index = -1
      end
    end

    private

    def __fw
      return if index >= items.size

      @index = [0, index].max

      context.instance_exec(items[index], &blk).tap do
        @index += 1
      end
    end

    def __bw
      return if index < 0

      @index = [index, items.size - 1].min

      context.instance_exec(items[index], &blk).tap do
        @index -= 1
      end
    end
  end
end

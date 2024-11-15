module Replay
  class Sequence
    attr_reader :identifier, :items, :index, :blk

    def initialize(identifier, items, blk)
      @identifier = identifier
      @items = items
      @index = -1
      @blk = blk
    end

    def forward(context, steps = 1)
      tindex = index + 1
      titems = items[tindex...(tindex + steps)]

      if titems.nil? || titems.empty?
        puts("WARN: No steps remaining for '#{identifier}' sequence, move backward or rewing")
        return
      end

      titems.map do |item|
        context.instance_exec(item, &blk).tap do
          @index += 1
        end
      end
    end

    def backward(context, steps = 1)
      tindex = index - steps + 1
      titems = items[tindex...(tindex + steps)]

      if titems.nil? || titems.empty?
        puts("WARN: No steps remaining for '#{identifier}' sequence, move forward")
        return
      end

      titems.reverse.map do |item|
        context.instance_exec(item, &blk).tap do
          @index -= 1
        end
      end
    end

    def rewind
      (@index + 1).tap do
        @index = -1
      end
    end
  end
end

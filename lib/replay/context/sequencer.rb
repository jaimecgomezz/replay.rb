module Replay
  class Context
    module Sequencer
      def start(name, items = nil)
        unless @__replay_sequence.nil?
          puts("WARN: Currently active '#{@__replay_sequence.identifier}' sequence, finish it first")
          return
        end

        sequence = @__replay_sequences[name.to_sym]

        if sequence.nil?
          puts("WARN: No '#{name}' sequence available")
          return
        end

        items ||= sequence[:defaults]

        raise(ArgumentError, "No items were provided to '#{name}' sequence start, nor has default items") if items.nil?
        raise(ArgumentError, "An enumerble must be provided to '#{name}' sequence: #{items}") unless items.is_a?(Enumerable)

        @__replay_sequence = Replay::Sequence.new(name.to_sym, items, sequence[:blk])

        @__replay_sequence.identifier
      end

      def fw(steps = 1)
        if @__replay_sequence.nil?
          puts('WARN: No active sequence, ignoring')
          return
        end

        raise(ArgumentError, "Expected a postive amount of steps forward: #{steps}") unless steps.is_a?(Integer) && steps.positive?

        @__replay_sequence.forward(self, steps)
      end

      def bw(steps = 1)
        if @__replay_sequence.nil?
          puts('WARN: No active sequence, ignoring')
          return
        end

        raise(ArgumentError, "Expected a postive amount of steps backwards: #{steps}") unless steps.is_a?(Integer) && steps.positive?

        @__replay_sequence.backward(self, steps)
      end

      def rw
        if @__replay_sequence.nil?
          puts('WARN: No active sequence, ignoring')
          return
        end

        @__replay_sequence.rewind
      end

      def finish
        if @__replay_sequence.nil?
          puts('WARN: No active sequence, ignoring')
          return
        end

        @__replay_sequence.identifier.tap do
          @__replay_sequence = nil
        end
      end
    end
  end
end

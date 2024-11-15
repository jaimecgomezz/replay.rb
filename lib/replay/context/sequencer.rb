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

        defaults, blk = sequence.values_at(:defaults, :blk)

        @__replay_sequence = Replay::Sequence.new(name.to_sym, items || defaults || [], blk)

        @__replay_sequence.identifier
      end

      def fw(steps = 1)
        if @__replay_sequence.nil?
          puts('WARN: No active sequence, ignoring')
          return
        end

        raise(ArgumentError, "Expected a postive amount of steps forward: #{steps}") unless steps.is_a?(Integer) && steps.positive?

        results = @__replay_sequence.forward(self, steps)

        return if results.nil?

        steps == 1 ? results.first : results
      end

      def bw(steps = 1)
        if @__replay_sequence.nil?
          puts('WARN: No active sequence, ignoring')
          return
        end

        raise(ArgumentError, "Expected a postive amount of steps backwards: #{steps}") unless steps.is_a?(Integer) && steps.positive?

        results = @__replay_sequence.backward(self, steps)

        return if results.nil?

        steps == 1 ? results.first : results
      end

      def rewind
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

        identifier = @__replay_sequence.identifier
        @__replay_sequence = nil
        identifier
      end
    end
  end
end

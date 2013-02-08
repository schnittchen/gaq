module Gaq
  class Target
    def initialize(origin, characteristics, instruction_stack_pair, tracker_name = nil)
      @origin, @characteristics, @instruction_stack_pair, @tracker_name =
        origin, characteristics, instruction_stack_pair, tracker_name
      @tracker_command_prefix = tracker_name ? "#{tracker_name}." : ''

      @our_tracker = Tracker.new(@instruction_stack_pair, @tracker_command_prefix, @tracker_name)
    end

    def tracker(tracker_name)
      @origin.target_from_characteristics(@characteristics, :tracker, tracker_name.to_s)
    end

    alias_method :[], :tracker

    def next_request
      @origin.target_from_characteristics(@characteristics, :next_request)
    end

    class << self
      def finalize
        delegate(*Tracker.tracker_methods, to: :@our_tracker)
      end

      def target_methods
        public_instance_methods(false)
      end
    end
  end
end

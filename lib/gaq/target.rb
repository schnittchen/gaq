module Gaq
  class Target
    def initialize(origin, characteristics, instruction_stack_pair, tracker_name = nil)
      @origin, @characteristics = origin, characteristics

      @our_tracker = Tracker.new(tracker_name, instruction_stack_pair)
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

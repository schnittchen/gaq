module Gaq
  class Target
    def initialize(origin, characteristics, instruction_stack_pair)
      @origin, @characteristics, @instruction_stack_pair =
        origin, characteristics, instruction_stack_pair
    end

    def tracker(tracker_name)
      @origin.target_from_characteristics(@characteristics, :tracker, tracker_name)
    end

    def next_request
      @origin.target_from_characteristics(@characteristics, :next_request)
    end

    class << self
      def finalize
        include Tracker.methods_module
      end

      def target_methods
        public_instance_methods(false) + Tracker.methods_module.instance_methods
      end
    end
  end
end

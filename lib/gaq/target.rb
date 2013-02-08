module Gaq
  class Target
    def initialize(origin, characteristics, instruction_stack_pair, tracker_name = nil)
      @origin, @characteristics, @instruction_stack_pair, @tracker_name =
        origin, characteristics, instruction_stack_pair, tracker_name
      @tracker_command_prefix = tracker_name ? "#{tracker_name}." : ''
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
        include Tracker.methods_module
      end

      def target_methods
        public_instance_methods(false) + Tracker.methods_module.instance_methods
      end
    end
  end
end

module Gaq
  class Options
    class LegacyOptions < ActiveSupport::OrderedOptions
      def initialize(default_tracker_config)
        super()
        @default_tracker_config = default_tracker_config

        self.track_pageview = true #TODO this is a tracker command
        self.anonymize_ip = false
        self.render_ga_js = :production
      end

      delegate :declare_variable, to: Variables
      delegate :web_property_id=, to: :@default_tracker_config

      def additional_trackers=(tracker_names_ary)
        Tracker.setup_for_additional_tracker_names(*tracker_names_ary)
      end

      def tracker(tracker_name)
        Tracker.tracker_config(tracker_name)
      end
    end

    def initialize(default_tracker_config)
      @default_tracker_config = default_tracker_config
    end

    def legacy
      @legacy_options ||= LegacyOptions.new(@default_tracker_config)
    end

    class << self
      attr_accessor :instance

      def build_instance(default_tracker_config)
        self.instance = new(default_tracker_config)
      end
    end
  end
end

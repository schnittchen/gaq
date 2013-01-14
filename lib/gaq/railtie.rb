require 'gaq/variables'
require 'gaq/tracker'

module Gaq
  module Helper
    def render_gaq
      gaq.render(self)
    end
  end

  module ControllerMethods
    def gaq
      @_gaq ||= Instance.for_controller(self)
    end
  end

  class Options < ActiveSupport::OrderedOptions
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

  class Railtie < Rails::Railtie
    config.gaq = Options.new(Tracker.default_tracker_config)

    config.after_initialize do
      Instance.finalize
    end

    initializer "gaq.include_helper" do |app|
      ActionController::Base.send :include, ControllerMethods
      ActionController::Base.helper Helper
      ActionController::Base.helper_method :gaq
    end
  end
end

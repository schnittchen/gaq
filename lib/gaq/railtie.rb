require 'gaq/variables'

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
    def initialize
      super
      self.web_property_id = 'UA-XUNSET-S'
      self.track_pageview = true
      self.anonymize_ip = false
      self.render_ga_js = :production
    end

    delegate :declare_variable, to: Variables
  end

  class Railtie < Rails::Railtie
    config.gaq = Options.new

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

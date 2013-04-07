require 'gaq/variables'
require 'gaq/tracker'
require 'gaq/options'

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

  class Railtie < Rails::Railtie
    Options.build_instance(Tracker.default_tracker_config)
    config.gaq = Options.instance.legacy

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

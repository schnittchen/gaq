require 'gaq/configuration'
require 'gaq/command_language'
require 'gaq/class_cache'
require 'gaq/controller_facade'
require 'gaq/controller_handle'
require 'gaq/snippet_renderer'

module Gaq
  module Helper
    def render_gaq
      renderer = SnippetRenderer.new(self, Configuration.singleton, Rails.env)
      renderer.render(_gaq_handle.finalized_commands_as_segments)
    end
  end

  module ControllerMethods
    def _gaq_handle
      @_gaq ||= ControllerHandle.new(
        ControllerFacade.new(self),
        CommandLanguage.singleton,
        ClassCache.singleton,
        Configuration.singleton
      )
    end

    def gaq
      _gaq_handle.root_target
    end
  end

  class Railtie < Rails::Railtie
    config.gaq = Configuration.singleton.rails_config

    initializer "gaq.include_helper" do |app|
      ActionController::Base.send :include, ControllerMethods
      ActionController::Base.helper Helper
      ActionController::Base.helper_method :_gaq_handle
    end
  end
end

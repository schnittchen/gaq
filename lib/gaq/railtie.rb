module Gaq
  module Helper
    def render_gaq
      gaq.render(self)
    end
  end

  module ControllerMethods
    def gaq
      @_gaq ||= Instance.new(self)
    end
  end

  module Variables
    # TODO move this out of the railtie
    # TODO refactor

    module Scope
      VISITOR = 1
      SESSION = 2
      PAGE    = 3
    end

    class  << self
      DEFAULT_VARIABLE_OPTIONS = {
        scope: Variables::Scope::PAGE
      }

      def declare_variable(name, options = {})
        normalize_variable_options options

        @variables ||= []
        @variables << {
          scope: options[:scope],
          slot: options[:slot],
          name: name
        }
      end

      def cleaned_up
        # TODO slot postprocessing
        @variables ||= []
        @variables
      end

      private

      def normalize_variable_options(options)
        options.reverse_merge! DEFAULT_VARIABLE_OPTIONS

        options[:scope] = Scope.const_get(options[:scope].to_s.upcase) unless \
          options[:scope].is_a? Fixnum
      end
    end
  end

  class Options < ActiveSupport::OrderedOptions
    attr_reader :foo

    def initialize
      super
      self.web_property_id = 'UA-XUNSET-S'
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

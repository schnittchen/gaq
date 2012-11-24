module Gaq
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

        variables << {
          scope: options[:scope],
          slot: options[:slot],
          name: name
        }
      end

      def cleaned_up
        variables
      end

      private

      def variables
        @variables ||= []
      end

      def normalize_variable_options(options)
        options.reverse_merge! DEFAULT_VARIABLE_OPTIONS

        options[:scope] = Scope.const_get(options[:scope].to_s.upcase) unless \
          options[:scope].is_a? Fixnum
      end
    end
  end
end

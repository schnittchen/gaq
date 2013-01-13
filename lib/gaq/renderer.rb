module Gaq
  class Renderer
    class << self
      def interpret_render_ga_js_config(render_ga_js, environment)
        case render_ga_js
        when TrueClass, FalseClass
          render_ga_js
        else
          Array(render_ga_js).map(&:to_s).include? environment
        end
      end
    end
  end
end
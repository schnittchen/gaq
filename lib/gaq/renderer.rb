module Gaq
  class Renderer

    SNIPPET = <<EOJ
(function() {
  var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
  ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
  (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(ga);
})();
EOJ

    def initialize(rendering_context, will_render_ga_js)
      @context = rendering_context
      @will_render_ga_js = will_render_ga_js
    end

    def render(calculated_instructions)
      quoted_instructions = calculated_instructions.map do |instruction|
        quote_instruction(instruction)
      end

      js_content_lines = [
        'var _gaq = _gaq || [];',
        "_gaq.push(#{quoted_instructions.join(",\n  ")});"
      ]

      js_content = js_content_lines.join("\n")
      js_content << "\n\n" << SNIPPET if @will_render_ga_js
      @context.javascript_tag js_content
    end

    private

    def quote_instruction(instruction)
      quoted_segments = instruction.map { |segment| "'#{@context.j segment.to_s}'" }.join ', '
      return "[#{quoted_segments}]"
    end

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

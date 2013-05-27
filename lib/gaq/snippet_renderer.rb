require 'json'

module Gaq
  class SnippetRenderer

    SNIPPET = <<EOJ
(function() {
  var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
  ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
  (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(ga);
})();
EOJ

    def initialize(rendering_context, config, rails_env)
      @context = rendering_context
      @config = config
      @rails_env = rails_env
    end

    def render(commands_as_segments)
      js_content_lines = [
        'var _gaq = _gaq || [];',
        "_gaq.push(#{escape_instructions(commands_as_segments).join(",\n  ")});"
      ]

      js_content = js_content_lines.join("\n")
      js_content << "\n\n" << SNIPPET if render_ga_js?

      return @context.javascript_tag js_content
    end

    private

    def escape_instructions(commands_as_segments)
      commands_as_segments.map do |command_as_segments|
        escape_instruction(command_as_segments)
      end
    end

    def escape_instruction(command_as_segments)
      "[#{command_as_segments.map(&:to_json).join(', ')}]"
    end

    def render_ga_js?
      @config.render_ga_js?(@rails_env)
    end
  end
end

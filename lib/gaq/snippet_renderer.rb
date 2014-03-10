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

    SNIPPET_THAT_SUPPORTS_DISPLAY_ADS = <<EOJ
(function() {
  var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
  ga.src = ('https:' == document.location.protocol ? 'https://' : 'http://') + 'stats.g.doubleclick.net/dc.js';
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
      if support_display_ads?
       js_content << "\n\n" << SNIPPET_THAT_SUPPORTS_DISPLAY_ADS if render_ga_js?
      else
        js_content << "\n\n" << SNIPPET if render_ga_js?
      end

      return @context.javascript_tag js_content
    end

    private

    def escape_instructions(commands_as_segments)
      commands_as_segments.map do |command_as_segments|
        command_as_segments.to_json
      end
    end

    def render_ga_js?
      @config.render_ga_js?(@rails_env)
    end

    def support_display_ads?
      @config.support_display_ads
    end
  end
end

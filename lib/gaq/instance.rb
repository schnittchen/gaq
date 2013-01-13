require 'gaq/quoting'
require 'gaq/variables'
require 'gaq/instruction_stack_pair'
require 'gaq/renderer'

module Gaq
  class Instance
    include Quoting

    def self.finalize
      DSL.finalize
    end

    module DSL
      # expects InnerDSL to be present

      def track_event(category, action, label = nil, value = nil, noninteraction = nil)
        event = [category, action, label, value, noninteraction].compact
        instruction '_trackEvent', *event
      end

      def self.finalize
        Variables.cleaned_up.each do |v|
          define_method "#{v[:name]}=" do |value|
            early_instruction '_setCustomVar', v[:slot], v[:name], value, v[:scope]
          end
        end
      end
    end

    module InnerDSL
      private

      def early_instruction(*args)
        @instructions_pair.early.push args
      end

      def instruction(*args)
        @instructions_pair.push args
      end
    end

    class NextRequestProxy
      include DSL
      include InnerDSL

      def initialize
        @instructions_pair = yield
      end
    end

    include DSL
    include InnerDSL

    class ConfigProxy
      def initialize(config, controller)
        @config, @controller = config, controller
      end

      def fetch(key)
        value = @config.send(key)
        value = value.call(@controller) if value.respond_to? :call
        return value
      end
    end

    def self.for_controller(controller)
      instruction_stack_pair, promise = InstructionStackPair.pair_and_next_request_promise(flash)
      config_proxy = ConfigProxy.new(Gaq.config, controller)

      new(instruction_stack_pair, promise, controller.flash, config_proxy)
    end

    def initialize(instruction_stack_pair, promise, flash, config_proxy)
      @instructions_pair, @promise , @flash, @config_proxy =
        instruction_stack_pair, promise, flash, config_proxy
    end

    def next_request
      @next_request ||= NextRequestProxy.new(&@promise)
    end

    private

    def fetch_config(key)
      @config_proxy.fetch(key)
    end

    def gaq_instructions
      [*setup_gaq_items, *@instructions_pair.early, *@instructions_pair.to_a]
    end

    def setup_gaq_items
      result = [
        ['_setAccount', fetch_config(:web_property_id)]
      ]
      result << ['_gat._anonymizeIp'] if fetch_config(:anonymize_ip)
      result << ['_trackPageview'] if fetch_config(:track_pageview)
      return result
    end

    def js_finalizer
      render_ga_js = fetch_config(:render_ga_js)
      render_ga_js = Renderer.interpret_render_ga_js_config(render_ga_js)

      return '' unless render_ga_js
      return <<EOJ
  (function() {
    var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
    ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
    (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(ga);
  })();
EOJ
    end

    public

    def render(context)
      quoted_gaq_items = gaq_instructions.map do |instruction_ary|
        quoted_gaq_item(*instruction_ary)
      end

      js_content_lines = [
        'var _gaq = _gaq || [];',
        "_gaq.push(#{quoted_gaq_items.join(",\n  ")});"
      ]

      js_content = js_content_lines.join("\n") + "\n" + js_finalizer
      context.javascript_tag js_content
    end
  end
end

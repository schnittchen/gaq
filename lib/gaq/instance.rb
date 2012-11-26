require 'gaq/quoting'
require 'gaq/instruction_stack'

module Gaq
  class Instance
    include Quoting

    def self.finalize
      DSL.finalize
    end

    module DSL
      # expects InnerDSL to be present

      def push_track_event(category, action, label = nil, value = nil, noninteraction = nil)
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
        @early_instructions.push_with_args args
      end

      def instruction(*args)
        @instructions.push_with_args args
      end
    end

    class NextRequestProxy
      include DSL
      include InnerDSL

      def initialize
        @early_instructions, @instructions = yield
      end
    end

    include DSL
    include InnerDSL

    def initialize(controller)
      @controller = controller

      @early_instructions, @instructions = InstructionStack.both_from_flash controller.flash
    end

    def next_request
      @next_request ||= NextRequestProxy.new do
        InstructionStack.both_into_flash @controller.flash
      end
    end

    private

    def evaluate_config(value)
      value = value.call(@controller) if value.respond_to? :call
      return value
    end

    def gaq_instructions
      [*setup_quoted_gaq_items, *@early_instructions.quoted_gaq_items, *@instructions.quoted_gaq_items]
    end

    def setup_quoted_gaq_items
      config = Gaq.config

      result = [
        quoted_gaq_item('_setAccount', evaluate_config(config.web_property_id))
      ]
      result << quoted_gaq_item('_gat._anonymizeIp') if evaluate_config(config.anonymize_ip)
      result << quoted_gaq_item('_trackPageview') if evaluate_config(config.track_pageview)
      return result
    end

    def js_finalizer
      render_ga_js = evaluate_config Gaq.config.render_ga_js
      case render_ga_js
      when TrueClass, FalseClass
      else
        render_ga_js = Array(render_ga_js).map(&:to_s).include? Rails.env
      end

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
      js_content_lines = [
        'var _gaq = _gaq || [];',
        "_gaq.push(#{gaq_instructions.join(",\n  ")});"
      ]

      js_content = js_content_lines.join("\n") + "\n" + js_finalizer
      context.javascript_tag js_content
    end
  end
end

require 'gaq/variables'
require 'gaq/instruction_stack'
require 'gaq/renderer'
require 'gaq/tracker'
require 'gaq/target_origin'

module Gaq
  class Instance
    def self.finalize
      Target.finalize
      delegate(*Target.target_methods, to: :@default_target)
    end

    class ConfigProxy
      def initialize(config, controller)
        @config, @controller = config, controller
      end

      def fetch(key, config_object = @config)
        value = config_object.send(key)
        value = value.call(@controller) if value.respond_to? :call
        return value
      end
    end

    def self.for_controller(controller)
      instruction_stack_pair, promise = InstructionStack.pair_and_next_request_promise(controller.flash)
      config_proxy = ConfigProxy.new(Gaq.config, controller)

      target_origin = TargetOrigin.new(instruction_stack_pair, promise)
      new(target_origin, config_proxy)
    end

    def initialize(target_origin, config_proxy)
      @target_origin, @config_proxy = target_origin, config_proxy
      @default_target = @target_origin.default_target
    end

    private

    def fetch_config(key)
      @config_proxy.fetch(key)
    end

    def gaq_instructions
      instruction_stack_pair = @target_origin.instruction_stack_pair
      [*setup_gaq_items, *instruction_stack_pair.ordered]
    end

    def setup_gaq_items
      result = Tracker.setup_instructions(@config_proxy)
      result << ['_gat._anonymizeIp'] if fetch_config(:anonymize_ip)
      result << ['_trackPageview'] if fetch_config(:track_pageview)
      return result
    end

    public

    def render(context)
      render_ga_js = fetch_config(:render_ga_js)
      render_ga_js = Renderer.interpret_render_ga_js_config(render_ga_js, Rails.env)

      Renderer.new(context, render_ga_js).render(gaq_instructions)
    end
  end
end

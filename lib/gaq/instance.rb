require 'gaq/variables'
require 'gaq/instruction_stack'
require 'gaq/renderer'
require 'gaq/tracker'
require 'gaq/target_origin'
require 'gaq/controller_facade'

module Gaq
  class Instance
    def self.finalize
      Target.finalize
      delegate(*Target.target_methods, to: :@default_target)
    end

    # @TODO get rid of
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
      controller_facade = ControllerFacade.new(controller)

      instruction_stack, promise = InstructionStack.stack_and_next_request_promise(controller.flash)
      config_proxy = ConfigProxy.new(Gaq.config, controller)

      target_origin = TargetOrigin.new(instruction_stack, promise)
      new(target_origin, config_proxy, controller_facade)
    end

    def initialize(target_origin, config_proxy, controller_facade)
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

    # make stubbable @TODO fix test smell
    def render_ga_js
      result = fetch_config(:render_ga_js)
      result = Renderer.interpret_render_ga_js_config(result, Rails.env)
    end

    public

    def render(context)
      Renderer.new(context, render_ga_js).render(gaq_instructions)
    end
  end
end

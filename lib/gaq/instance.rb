require 'gaq/variables'
require 'gaq/instruction_stack_pair'
require 'gaq/renderer'
require 'gaq/tracker'

module Gaq
  class Instance
    def self.finalize
      include Tracker.methods_module

      NextRequestProxy.finalize
    end

    class NextRequestProxy
      def self.finalize
        include Tracker.methods_module
      end

      def initialize
        @instructions_stack_pair = yield
      end
    end

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
      instruction_stack_pair, promise = InstructionStackPair.pair_and_next_request_promise(controller.flash)
      config_proxy = ConfigProxy.new(Gaq.config, controller)

      new(instruction_stack_pair, promise, controller.flash, config_proxy)
    end

    def initialize(instruction_stack_pair, promise, flash, config_proxy)
      @instructions_stack_pair, @promise , @flash, @config_proxy =
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
      [*setup_gaq_items, *@instructions_stack_pair.early, *@instructions_stack_pair.to_a]
    end

    def setup_gaq_items
      result = [
        ['_setAccount', fetch_config(:web_property_id)]
      ]
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

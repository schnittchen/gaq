module Gaq
  module Tracker
    ## expects a @instruction_stack_pair and a @tracker_command_prefix

    def track_event(category, action, label = nil, value = nil, noninteraction = nil)
      event = [category, action, label, value, noninteraction].compact
      @instruction_stack_pair.push tracker_command('_trackEvent', *event)
    end

    private

    def tracker_command(cmd_name, *args)
      [@tracker_command_prefix + cmd_name, *args]
    end

    class Options < ActiveSupport::OrderedOptions
      def initialize
        super
        self.web_property_id = 'UA-XUNSET-S'
      end
    end

    class << self
      def pre_setup
        @tracker_data = { nil => Options.new }
      end

      def setup_for_additional_tracker_names(*tracker_names)
        tracker_names.map(&:to_s).each_with_object(@tracker_data) do |tracker_name, data|
          data[tracker_name] = Options.new
        end
      end

      def tracker_config(tracker_name)
        @tracker_data[tracker_name.to_s]
      end

      def default_tracker_config
        @tracker_data[nil]
      end

      def setup_instructions(config_proxy)
        @tracker_data.map do |tracker_name, options|
          web_property_id = config_proxy.fetch(:web_property_id, options)
          command = '_setAccount'
          command.prepend "#{tracker_name}." if tracker_name
          [command, web_property_id]
        end
      end

      def methods_module
        @methods_module ||= clone.module_eval do
          Variables.cleaned_up.each do |v|
            define_method "#{v[:name]}=" do |value|
              @instruction_stack_pair.early.push tracker_command('_setCustomVar', v[:slot], v[:name], value, v[:scope])
            end
          end

          self
        end
      end

      # happy testing!
      def reset_methods_module
        @methods_module = nil
      end
    end

    pre_setup
  end
end

require 'active_support/ordered_options'

require 'gaq/instruction/set_account'
require 'gaq/instruction/track_event'
require 'gaq/instruction/set_custom_var'

module Gaq
  class Tracker
    def initialize(name, instruction_stack_pair)
      @instruction_stack_pair, @tracker_name = instruction_stack_pair, name
      extend self.class.variable_methods
    end

    def track_event(category, action, label = nil, value = nil, noninteraction = nil)
      event = [category, action, label, value, noninteraction].compact
      instruction = Instruction::TrackEvent.new event
      instruction.for_tracker @tracker_name
      @instruction_stack_pair.push instruction
    end

    private

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

      def tracker_methods
        [*public_instance_methods(false), *Tracker.variable_methods.public_instance_methods(false)]
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
          Instruction::SetAccount.new [web_property_id]
        end
      end

      def variable_methods
        @variable_methods ||= Module.new.module_eval do
          Variables.cleaned_up.each do |v|
            define_method "#{v[:name]}=" do |value|
              instruction = Instruction::SetCustomVar.new [v[:slot], v[:name], value, v[:scope]]
              @instruction_stack_pair.push instruction
            end
          end

          self
        end
      end

      # happy testing!
      def reset_variable_methods
        @variable_methods = nil
      end
    end

    pre_setup
  end
end

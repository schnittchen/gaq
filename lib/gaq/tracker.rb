require 'active_support/ordered_options'

require 'gaq/instruction/set_account'
require 'gaq/instruction/track_event'
require 'gaq/instruction/set_custom_var'
require 'gaq/fetch_config_value'
require 'gaq/tracker_pool'

module Gaq
  class Tracker
    def initialize(name, instruction_stack)
      @instruction_stack, @tracker_name = instruction_stack, name
      extend self.class.variable_methods
    end

    def track_event(category, action, label = nil, value = nil, noninteraction = nil)
      event = [category, action, label, value, noninteraction].compact
      instruction = Instruction::TrackEvent.new event
      instruction.for_tracker @tracker_name
      @instruction_stack.push instruction
    end

    private

    class Options < ActiveSupport::OrderedOptions
      def initialize
        super
        self.web_property_id = 'UA-XUNSET-S'
      end
    end

    # @TODO bad singleton
    class << self
      include FetchConfigValue

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

      def setup_instructions(controller_facade)
        @tracker_data.map do |tracker_name, options|
          web_property_id = fetch_config_value(:web_property_id, options)
          Instruction::SetAccount.new [web_property_id]
        end
      end

      delegate :variable_methods, :reset_variable_methods, :tracker_methods, to: :pool

      private

      def pool
        TrackerPool.new
      end
    end

    pre_setup
  end
end

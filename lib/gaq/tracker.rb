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

    # @TODO bad singleton
    class << self

      def pre_setup
      end

      delegate :variable_methods, :reset_variable_methods, :tracker_methods,
        :setup_for_additional_tracker_names,
        :tracker_config, :default_tracker_config, :setup_instructions,
        to: :pool

      private

      def pool
        @pool ||= TrackerPool.new
      end
    end

    pre_setup
  end
end

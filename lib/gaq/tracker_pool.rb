module Gaq
  class TrackerPool
    include FetchConfigValue

    class Options < ActiveSupport::OrderedOptions
      def initialize
        super
        self.web_property_id = 'UA-XUNSET-S'
      end
    end

    def initialize
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

    def variable_methods
      @variable_methods ||= Module.new.module_eval do
        Variables.cleaned_up.each do |v| #@TODO inject variables
          define_method "#{v[:name]}=" do |value|
            instruction = Instruction::SetCustomVar.new [v[:slot], v[:name], value, v[:scope]]
            @instruction_stack.push instruction
          end
        end

        self
      end
    end

    def tracker_methods
      [
        *Tracker.public_instance_methods(false),
        *variable_methods.public_instance_methods(false)
      ]
    end

    # happy testing!
    def reset_variable_methods
      @variable_methods = nil
    end


  end
end

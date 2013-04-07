module Gaq
  class TrackerPool

    class Options < ActiveSupport::OrderedOptions
      def initialize
        super
        self.web_property_id = 'UA-XUNSET-S'
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

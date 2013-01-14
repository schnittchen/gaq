module Gaq
  module Tracker
    def track_event(category, action, label = nil, value = nil, noninteraction = nil)
      event = [category, action, label, value, noninteraction].compact
      @instruction_stack_pair.push ['_trackEvent', *event]
    end

    class << self
      def methods_module
        @methods_module ||= clone.module_eval do
          Variables.cleaned_up.each do |v|
            define_method "#{v[:name]}=" do |value|
              @instruction_stack_pair.early.push ['_setCustomVar', v[:slot], v[:name], value, v[:scope]]
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
  end
end

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

    class << self
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
  end
end

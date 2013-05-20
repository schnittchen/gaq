module Gaq
  class DslTarget
    def initialize(target_factory, factory_token, new_command_proc, commands, tracker_name)
      @target_factory, @factory_token, @new_command_proc, @commands, @tracker_name =
        target_factory, factory_token, new_command_proc, commands, tracker_name
    end

    def tracker(tracker_name)
      @target_factory.target_with_tracker_name(tracker_name, @factory_token)
    end

    alias_method :[], :tracker

    def next_request
      @target_factory.target_for_next_request(@factory_token)
    end

    ## tracker methods

    def track_event(category, action, label = nil, value = nil, noninteraction = nil)
      array = [noninteraction, value, label, action, category]
      4.times do
        if array.first.nil?
          array.shift
        else
          break
        end
      end

      command = @new_command_proc.call(:track_event, *array.reverse)
      command.tracker_name = @tracker_name
      @commands << command
    end

    class << self
      def variable_commands_module(variables)
        Module.new do
          variables.each do |variable|
            module_eval <<-RUBY_EVAL, __FILE__, __LINE__ + 1
              def #{variable.name}=(value)
                command = @new_command_proc.call(:set_custom_var, #{variable.slot}, #{variable.name.inspect}, value, #{variable.scope})
                command.tracker_name = @tracker_name
                @commands << command
              end
            RUBY_EVAL
          end
        end
      end
    end
  end
end

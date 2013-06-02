require 'gaq/dsl_target'
require 'gaq/command_language'

module Gaq
  class DslTargetFactory
    attr_writer :target_base_class #for injecting

    def initialize(class_cache, flash_commands_adapter, immediate_commands, new_command_proc, variables, tracker_names)
      @class_cache = class_cache
      @flash_commands_adapter = flash_commands_adapter
      @immediate_commands = immediate_commands
      @new_command_proc = new_command_proc
      @variables = variables
      @tracker_names = tracker_names
    end

    def root_target
      target_for_token(Token.new)
    end

    def target_with_tracker_name(tracker_name, token)
      tracker_name = tracker_name.to_s unless tracker_name.nil?
      raise "No tracker by name #{tracker_name.inspect}" unless @tracker_names.include?(tracker_name)

      token = token.dup
      token.tracker_name = tracker_name
      target_for_token(token)
    end

    def target_for_next_request(token)
      token = token.dup
      token.next_request = true
      target_for_token(token)
    end

    private

    Token = Struct.new(:tracker_name, :next_request) do
      alias_method :next_request?, :next_request
    end

    def target_for_token(token)
      commands = token.next_request? ? @flash_commands_adapter : @immediate_commands
      target_class.new(self, token, @new_command_proc, commands, token.tracker_name)
    end

    def target_base_class
      @target_base_class || DslTarget
    end

    def target_class
      ensure_class_cache_set_up
      @class_cache[:target_class]
    end

    def ensure_class_cache_set_up
      @class_cache_set_up ||= true.tap do
        @class_cache.building(:target_class, target_base_class) do |cls|
          cls.send :include, target_base_class.variable_commands_module(@variables)
        end
      end
    end
  end
end

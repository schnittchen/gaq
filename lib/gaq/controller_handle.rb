# encoding: utf-8

# require 'gaq/class_cache' #why?
require 'gaq/dsl_target_factory'
require 'gaq/flash_commands_adapter'

module Gaq
  class ControllerHandle
    attr_writer :flash_commands_adapter

    def initialize(controller_facade, language, class_cache, config)
      @controller_facade, @language, @class_cache, @config =
        controller_facade, language, class_cache, config
    end

    def root_target
      @root_target ||= target_factory.root_target
    end

    def immediate_commands
      @immediate_commands ||= flash_commands_adapter.commands_from_flash
    end

    def finalized_commands_as_segments
      commands = immediate_commands.dup

      setup_tracker_names = [nil, *seen_tracker_names].uniq
      setup_tracker_names.each do |tracker_name|
        tracker_config = @config.tracker_config(tracker_name)
        # nil check here!
        commands += tracker_setup_commands(tracker_config)
      end

      @language.sort_commands(commands)
      @language.commands_to_segments_for_to_json(commands)
    end

    private

    def seen_tracker_names
      immediate_commands.map(&:tracker_name).uniq
    end

    def tracker_setup_commands(tracker_config)
      [set_account_command(tracker_config), track_pageview_command(tracker_config)].compact
    end

    def track_pageview_command(tracker_config)
      return nil unless tracker_config.track_pageview?

      command = @language.new_command(:track_pageview)
      command.tracker_name = tracker_config.tracker_name
      command
    end

    def set_account_command(tracker_config)
      command = @language.new_command(:set_account, tracker_config.web_property_id)
      command.tracker_name = tracker_config.tracker_name
      command
    end

    def target_factory
      @target_factory ||= DslTargetFactory.new(
        @class_cache, flash_commands_adapter, immediate_commands,
        new_command_proc, variables, @config.tracker_names)
    end

    def flash_commands_adapter
      @flash_commands_adapter ||= FlashCommandsAdapter.new(@language, @controller_facade)
    end

    def new_command_proc
      @language.method(:new_command)
    end

    def variables
      @config.variables.values
    end
  end
end

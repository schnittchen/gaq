require 'forwardable'
require 'active_support/ordered_options'

module Gaq
  class Configuration
    attr_reader :rails_config, :variables

    RAILS_CONFIG_ACCESSORS = [:anonymize_ip, :render_ga_js]
    attr_accessor(*RAILS_CONFIG_ACCESSORS)

    VariableException = Class.new(RuntimeError)

    Variable = Struct.new(:slot, :name, :scope) do
      SCOPE_MAP = {
        nil => 3, #we allow for a default @TODO check documentation

        :visitor => 1,
        :session => 2,
        :page => 3,

        1 => 1,
        2 => 2,
        3 => 3
      }

      def initialize(slot, name, scope)
        super(slot, name)
        set_scope scope
      end

      private

      def set_scope(scope)
        self.scope = SCOPE_MAP.fetch(scope) do
          raise VariableException, "unknown scope #{scope.inspect}"
        end
      end
    end

    def initialize
      default_tracker_config = TrackerConfig.new(nil)
      @default_tracker_rails_config = default_tracker_config.rails_config

      @tracker_configs = { nil => default_tracker_config }
      @rails_config = RailsConfig.new(self, default_tracker_config)
      @variables = {}
    end

    def declare_variable(name, options = {})
      # @TODO deprecate use without slot given
      # We just code like it's always given here
      slot = options[:slot]
      # @TODO raise when slot off limits
      raise VariableException, "Already have a variable at that slot" if
        @variables.find { |_, var| var.slot == slot }
      raise VariableException, "Already have a variable of that name" if
        @variables.find { |_, var| var.name == name }

      variable = Variable.new(slot, name, options[:scope])
      @variables[name] = variable
    end

    def register_tracker_name(name)
      name = name.to_s
      # @TODO check for collision, assert name format

      raise "duplicate tracker name" if @tracker_configs.key?(name)
      @tracker_configs[name] = TrackerConfig.new(name)
    end

    def tracker_rails_config(name) # name can be nil -> default tracker
      name = name.to_s unless name.nil?
      tracker_config = @tracker_configs.fetch(name) { raise "No tracker by that name (#{name.inspect})" }
      tracker_config.rails_config
    end

    def tracker_configs
      @tracker_configs.values
    end

    def render_ga_js?(environment)
      environment = environment.to_s

      case render_ga_js
      when TrueClass, FalseClass
        render_ga_js
      when Array, Symbol
        Array(render_ga_js).map(&:to_s).include? environment
      else
        render_ga_js
      end
    end

    class TrackerConfig
      attr_reader :rails_config, :tracker_name

      RAILS_CONFIG_ACCESSORS = [:web_property_id, :track_pageview]
      attr_accessor(*RAILS_CONFIG_ACCESSORS)

      def initialize(tracker_name)
        @tracker_name = tracker_name

        @track_pageview = true
        @rails_config = RailsConfig.new(self)
      end

      class RailsConfig
        extend Forwardable
        def_delegators :@config, *RAILS_CONFIG_ACCESSORS.map { |m| "#{m}=" }

        def initialize(config)
          @config = config
        end
      end
    end

    class RailsConfig
      extend Forwardable
      def_delegators :@config, :declare_variable,
        *Configuration::RAILS_CONFIG_ACCESSORS.map { |m| "#{m}=" }
      def_delegators :@default_tracker_rails_config,
        *TrackerConfig::RAILS_CONFIG_ACCESSORS.map { |m| "#{m}=" }

      def initialize(config, default_tracker_rails_config)
        @config = config

        @default_tracker_rails_config = default_tracker_rails_config

        @anonymize_ip = false
        @render_ga_js = :production
      end


      def additional_trackers=(array)
        raise "you can only do this once" if @trackers_set
        @trackers_set = true

        array.each { |name| @config.register_tracker_name(name) }
      end

      def tracker(name)
        @config.tracker_rails_config(name)
      end
    end

    class << self
      def instance
        @instance ||= new
      end
    end
  end
end
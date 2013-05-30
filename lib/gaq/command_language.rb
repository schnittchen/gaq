require 'gaq/boolean'

module Gaq
  class CommandLanguage
    attr_writer :value_coercer
    attr_writer :value_preserializer
    attr_writer :value_deserializer

    def initialize
      @descriptors = {}
    end

    CommandDescriptor = Struct.new(:signature, :name, :identifier, :sort_slot)

    def knows_command(identifier)
      @descriptors[identifier] = CommandDescriptor.new.tap do |desc|
        desc.identifier = identifier
        yield desc
      end
      self
    end

    def commands_to_flash_items(commands)
      commands.map do |command|
        command_to_segments(command)
      end
    end

    # this happens to be the same, but may be different in the future
    alias_method :commands_to_segments_for_to_json, :commands_to_flash_items

    def commands_from_flash_items(flash_items)
      flash_items.map do |flash_item|
        descriptor, tracker_name = descriptor_and_tracker_name_from_first_segment(flash_item.first)
        params = deserialize_items(flash_item.drop(1), descriptor.signature)
        Command.new(descriptor, descriptor.name, params, tracker_name)
      end
    end

    # modifies commands
    def sort_commands(commands)
      sorted_pairs = commands.each_with_index.sort_by do |command, index|
        [
          command.descriptor.sort_slot || sort_slot_fallback,
          index
        ]
      end
      commands.replace sorted_pairs.map(&:first)
    end

    def new_command(identifier, *params)
      descriptor = @descriptors.fetch(identifier) { raise "no command with identifier #{identifier.inspect}" }
      params = coerce_params(params, descriptor.signature)

      Command.new(descriptor, descriptor.name, params)
    end

    Command = Struct.new(:descriptor, :name, :params, :tracker_name)

    private

    def sort_slot_fallback
      @sort_slot_fallback ||= @descriptors.values.map(&:sort_slot).compact.max + 1
    end

    def command_to_segments(command)
      descriptor = command.descriptor

      params = pre_serialize_params(command.params, descriptor.signature)

      first_segment = first_segment_from_descriptor_and_tracker_name(descriptor, command.tracker_name)
      [first_segment, *params]
    end

    def first_segment_from_descriptor_and_tracker_name(descriptor, tracker_name)
      [tracker_name, descriptor.name].compact.join('.')
    end

    def descriptor_and_tracker_name_from_first_segment(first_segment)
      split = first_segment.split('.')
      command_name, tracker_name = split.reverse
      descriptor = @descriptors.values.find { |desc| desc.name == command_name }
      [descriptor, tracker_name]
    end

    def coerce_params(params, signature)
      signature = signature.take(params.length)
      signature.zip(params).map do |type, param|
        @value_coercer.call(type, param)
      end
    end

    def pre_serialize_params(params, signature)
      signature = signature.take(params.length)
      signature.zip(params).map do |type, param|
        @value_preserializer.call(type, param)
      end
    end

    def deserialize_items(items, signature)
      signature = signature.take(items.length)
      signature.zip(items).map do |type, item|
        @value_deserializer.call(type, item)
      end
    end

    def self.declare_language_on(instance)
      instance.knows_command(:set_account) do |desc|
        desc.name = "_setAccount"
        desc.signature = [String]
        desc.sort_slot = 0
      end

      instance.knows_command(:track_pageview) do |desc|
        desc.name = "_trackPageview"
        desc.signature = [String]
        desc.sort_slot = 1
      end

      instance.knows_command(:track_event) do |desc|
        desc.name = "_trackEvent"
        desc.signature = [String, String, String, Integer, Boolean]
      end

      instance.knows_command(:set_custom_var) do |desc|
        desc.name = "_setCustomVar"
        desc.signature = [Integer, String, String, Integer]
        desc.sort_slot = 2
      end
    end

    # @TODO
    def self.define_transformations_on(instance)
      instance.value_coercer = ->(type, x) {x}
      instance.value_preserializer = ->(type, x) {x}
      instance.value_deserializer = ->(type, x) {x}
    end

    def self.singleton
      new.tap do |result|
        declare_language_on(result)
        define_transformations_on(result)
      end
    end
  end
end

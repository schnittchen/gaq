# encoding: utf-8

module Gaq
  class CommandLanguage
    attr_writer :value_coercer
    attr_writer :value_preserializer
    attr_writer :value_deserializer

    def initialize
      @descriptors = {}
    end

    CommandDescriptor = Struct.new(:signature, :name, :identifier)

    def knows_command(identifier)
      @descriptors[identifier] = CommandDescriptor.new.tap do |desc|
        desc.identifier = identifier
        yield desc
      end
      self
    end

    def commands_to_flash_items(commands)
      commands.map do |command|
        descriptor = @descriptors[command.identifier]

        params = pre_serialize_params(command.params, descriptor.signature)

        first_segment = first_segment_from_descriptor_and_tracker_name(descriptor, command.tracker_name)
        [first_segment, *params]
      end
    end

    def commands_from_flash_items(flash_items)
      flash_items.map do |flash_item|
        descriptor, tracker_name = descriptor_and_tracker_name_from_first_segment(flash_item.first)
        params = deserialize_items(flash_item.drop(1), descriptor.signature)
        Command.new(descriptor.identifier, descriptor.name, params, tracker_name)
      end
    end

    def new_command(identifier, *params)
      descriptor = @descriptors.fetch(identifier) { raise "no command with identifier #{identifier.inspect}" }
      params = coerce_params(params, descriptor.signature)

      Command.new(identifier, descriptor.name, params)
    end

    Command = Struct.new(:identifier, :name, :params, :tracker_name)

    private

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

    def self.singleton
      # XXX
    end
  end
end

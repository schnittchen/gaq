require 'gaq/boolean'

module Gaq
  module InstructionParamType
    class << self
      def jsonify(value, type)
        prepare_for_to_json(coerce(value, type), type).to_json
      end

      def coerce(value, type)
        case type.name.split('::').last
        when 'String'
          value.to_s
        when 'Integer'
          value.to_i
        when 'Boolean'
          !!value
        end
      end

      private

      def prepare_for_to_json(value, type)
        type.name.split('::').last == 'Boolean' ? Boolean.new(value) : value
      end

    end
  end
end

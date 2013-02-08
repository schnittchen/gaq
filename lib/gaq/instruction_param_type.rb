require 'gaq/boolean'

module Gaq
  module InstructionParamType
    class << self
      def jsonify(value, type)
        coerce(value, type).to_json
      end

      private

      def coerce(value, type)
        case type.name.split('::').last
        when 'String'
          value.to_s
        when 'Integer'
          value.to_i
        when 'Boolean'
          Boolean.new(value)
        end
      end
    end
  end
end

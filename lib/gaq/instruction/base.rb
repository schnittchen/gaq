require 'json'

require 'gaq/instruction_param_type'

module Gaq
  module Instruction
    class Base
      POS_IDENTS = [:initial, :setup, :variables, :main]

      delegate :position_ident, to: 'self.class'

      attr_reader :tracker_name

      def initialize(params)
        @params = params.zip(get_signature.take(params.length)).map do |param, type|
          InstructionParamType.coerce(param, type)
        end
      end

      def for_tracker(tracker_name)
        @tracker_name = tracker_name
        self
      end

      def json_parameters
        @params.zip(get_signature.take(@params.length)).map do |param, type|
          InstructionParamType.jsonify(param, type)
        end
      end

      def to_json
        "[#{[full_first_array_item, *json_parameters].join(', ')}]"
      end

      def position_slot
        POS_IDENTS.index(position_ident)
      end

      def serialize
        [full_first_word, *@params]
      end

      def ==(other)
        other.class == self.class &&
          other.instance_variable_get(:@params) == @params
      end

      private

      def full_first_word
        [@tracker_name, get_tracker_method].compact.join('.')
      end

      def full_first_array_item
        InstructionParamType.jsonify(full_first_word, String)
      end

      delegate :get_tracker_method, :get_signature, to: 'self.class'

      class << self
        # dsl methods

        def positionable(pos_ident)
          @position_ident = pos_ident
        end

        def tracker_method(name = nil)
          @tracker_method = name
        end

        def signature(*types)
          @signature = types
        end

        # getters

        def get_signature
          @signature
        end

        def get_tracker_method
          @tracker_method
        end

        # flash deserialization

        def deserialize(item)
          tracker_method = item.first.split('.').last
          instruction_class_for_tracker_method(tracker_method).new item[1..-1]
        end

        # utility

        def instruction_class_for_tracker_method(tracker_method)
          @subclasses.find { |cls| cls.get_tracker_method == tracker_method }
        end

        def inherited(subclass)
          @subclasses ||= []
          @subclasses << subclass
        end
      end
    end
  end
end

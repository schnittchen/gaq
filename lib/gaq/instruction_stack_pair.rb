require 'active_support/core_ext/module/delegation'

module Gaq
  class InstructionStackPair
    def initialize(early = [], regular = [])
      _, @regular = early, regular
    end

    delegate :push, :to_a, to: :@regular

    FLASH_KEY = :analytics_instructions #TODO change this

    def ordered
      @regular.sort_by(&:position_slot)
    end

    class FlashArray < Array
      def push(instruction)
        super(instruction.serialize)
      end
    end

    class << self
      def pair_and_next_request_promise(flash)
        args = (flash[FLASH_KEY] || []).map do |array|
          (array || []).map do |item|
            Instruction::Base.deserialize(item)
          end
        end
        pair = new([], Array(args.inject(:+)))
        promise = -> do
          flash[FLASH_KEY] = [FlashArray.new, FlashArray.new]
          new(*flash[FLASH_KEY])
        end

        [pair, promise]
      end
    end
  end
end

require 'active_support/core_ext/module/delegation'

module Gaq
  class InstructionStack
    def initialize(instructions = [])
      @instructions = instructions
    end

    delegate :push, :to_a, to: :@instructions

    FLASH_KEY = :gaqgem

    def ordered
      @instructions.sort_by(&:stack_sort_value)
    end

    class FlashArray
      # we maintain the flash stack and its instructions separately.
      # this way we can provide reproducable flash content for the tests.
      def initialize
        @stack_in_flash = []
        @instructions = []
        yield @stack_in_flash
      end

      def push(instruction)
        @instructions.push instruction
        @instructions.sort_by!(&:stack_sort_value)
        @stack_in_flash.replace @instructions.map { |ins| ins.serialize }
      end
    end

    class << self
      def stack_and_next_request_promise(flash)
        if instructions = flash[FLASH_KEY]
          instructions = instructions.map { |item| Instruction::Base.deserialize(item) }
        else
          instructions = []
        end

        stack = new(instructions)
        promise = -> do
          instructions = FlashArray.new do |stack_in_flash|
            flash[FLASH_KEY] = stack_in_flash
          end
          new(instructions)
        end

        [stack, promise]
      end
    end
  end
end

require 'gaq/quoting'

module Gaq
  class InstructionStack
    FLASH_KEY = :analytics_instructions

    def self.both_from_flash(flash)
      early, normal = flash[FLASH_KEY] || [[], []]
      [new(early), new(normal)]
    end

    def self.both_into_flash(flash)
      early, normal = flash[FLASH_KEY] = [[], []]
      [new(early), new(normal)]
    end

    def initialize(stack)
      @stack = stack
    end

    def push_with_args(args)
      @stack << args
    end

    def to_a
      @stack
    end
  end
end

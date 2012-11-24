require 'gaq/quoting'

module Gaq
  class InstructionStack
    include Quoting

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
      @stack << quoted_gaq_item(*args)
    end

    def quoted_gaq_items
      @stack
    end
  end
end

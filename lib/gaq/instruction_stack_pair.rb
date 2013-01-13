require 'active_support/core_ext/module/delegation'

module Gaq
  class InstructionStackPair
    attr_reader :early

    def initialize(early = [], regular = [])
      @early, @regular = early, regular
    end

    delegate :push, :to_a, to: :@regular

    FLASH_KEY = :analytics_instructions #TODO change this

    class << self
      def pair_and_next_request_promise(flash)
        pair = new(*flash[FLASH_KEY])
        promise = -> do
          flash[FLASH_KEY] = [[], []]
          new(*flash[FLASH_KEY])
        end

        [pair, promise]
      end
    end
  end
end

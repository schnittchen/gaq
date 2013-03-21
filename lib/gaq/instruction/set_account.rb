require 'gaq/instruction/base'

module Gaq
  module Instruction
    class SetAccount < Base
      stack_position :initial

      tracker_method '_setAccount'

      signature String
    end
  end
end

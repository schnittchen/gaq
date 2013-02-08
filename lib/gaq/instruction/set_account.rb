module Gaq
  module Instruction
    class SetAccount < Base
      positionable :initial

      tracker_method '_setAccount'

      signature String
    end
  end
end

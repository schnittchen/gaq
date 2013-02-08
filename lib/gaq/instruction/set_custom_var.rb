module Gaq
  module Instruction
    class SetCustomVar < Base
      positionable :variables

      tracker_method '_setCustomVar'

      signature Integer, String, String, Integer
    end
  end
end

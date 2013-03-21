require 'gaq/instruction/base'

module Gaq
  module Instruction
    class SetCustomVar < Base
      stack_position :variables

      tracker_method '_setCustomVar'

      signature Integer, String, String, Integer
    end
  end
end

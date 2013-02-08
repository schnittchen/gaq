module Gaq
  module Instruction
    class TrackPageview < Base
      positionable :setup

      tracker_method '_trackPageview'

      signature String
    end
  end
end

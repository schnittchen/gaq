require 'gaq/instruction/base'

module Gaq
  module Instruction
    class TrackEvent < Base
      tracker_method '_trackEvent'

      signature String, String, String, Integer, Boolean
    end
  end
end

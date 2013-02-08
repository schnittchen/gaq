module Gaq
  class Boolean
    def initialize(boolish)
      @value = !!boolish
    end

    def to_json
      @value.to_s
    end
  end
end

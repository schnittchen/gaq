module Gaq
  class Boolean
    def initialize(bool)
      @value = bool
    end

    def to_json
      @value.to_s
    end
  end
end

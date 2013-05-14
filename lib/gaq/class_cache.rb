module Gaq
  class ClassCache
    Miss = Class.new(RuntimeError)

    def initialize
      @cached = Hash.new { |hash, key| hash[key] = build(key) }
      @build_instructions = {}
    end

    def building(key, base_class, &block)
      @build_instructions[key] = [base_class, block]
      self
    end

    def [](key)
      @cached[key]
    end

    def self.singleton
      @singleton ||= new
    end

    private

    def build(key)
      raise Miss, "Nothing registered for key #{key.inspect}" unless @build_instructions.key?(key)
      base_class, block = @build_instructions[key]

      Class.new(base_class).tap(&block)
    end
  end
end

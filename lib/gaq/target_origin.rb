require 'gaq/target'

module Gaq
  class TargetOrigin
    attr_reader :default_target, :instruction_stack_pair

    class Characteristics < Struct.new(:tracker_name, :is_for_next_request)
      alias_method :for_next_request?, :is_for_next_request
    end

    def initialize(instruction_stack_pair, next_request_promise)
      @instruction_stack_pair, @promise = instruction_stack_pair, next_request_promise

      base_characteristics = characterize(nil, false)
      @default_target = Target.new(self, base_characteristics, @instruction_stack_pair)

      @targets = {
        base_characteristics => @default_target
      }
    end

    def target_from_characteristics(base, dsl_method, *args)
      characteristics = case dsl_method
      when :tracker
        characterize_with_base(args.first, nil, base)
      when :next_request
        characterize_with_base(nil, true, base)
      end

      @targets[characteristics] ||= create_target(characteristics)
    end

    private

    def create_target(characteristics)
      if characteristics.is_for_next_request
        instruction_stack_pair = (@next_request_instruction_stack_pair ||= @promise.call)
      else
        instruction_stack_pair = @instruction_stack_pair
      end

      Target.new(self, characteristics, instruction_stack_pair, characteristics.tracker_name)
    end

    def characterize_with_base(tracker_name, is_for_next_request, base)
      result = base.dup
      result.tracker_name = tracker_name if tracker_name
      result.is_for_next_request = is_for_next_request if is_for_next_request
      result
    end

    def characterize(tracker_name, is_for_next_request)
      Characteristics.new(tracker_name, is_for_next_request)
    end
  end
end

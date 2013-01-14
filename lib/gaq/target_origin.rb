require 'gaq/target'

module Gaq
  class TargetOrigin
    attr_reader :default_target, :instruction_stack_pair

    def initialize(instruction_stack_pair, next_request_promise)
      @instruction_stack_pair, @promise = instruction_stack_pair, next_request_promise

      base_characteristict = characterize(nil, false)
      @default_target = Target.new(self, base_characteristict, @instruction_stack_pair)

      @targets = {
        base_characteristict => @default_target
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
      tracker_name = characteristics.first
      is_for_next_request = characteristics[1]

      if is_for_next_request
        instruction_stack_pair = (@next_request_instruction_stack_pair ||= @promise.call)
      else
        instruction_stack_pair = @instruction_stack_pair
      end

      command_prefix = tracker_name ? "#{tracker_name}." : ''
      Target.new(self, characteristics, instruction_stack_pair, command_prefix)
    end

    def characterize_with_base(tracker_name, is_for_next_request, base)
      tracker_name ||= base.first
      is_for_next_request = base[1] if is_for_next_request.nil?
      characterize(tracker_name, is_for_next_request)
    end

    def characterize(tracker_name, is_for_next_request)
      [tracker_name, is_for_next_request]
    end
  end
end

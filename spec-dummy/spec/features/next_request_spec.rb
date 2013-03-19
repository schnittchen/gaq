require 'spec_helper'
require 'common_spec_methods'

describe "gaq next_request effect" do
  it "renders events after redirect, but not after the request following" do
    visit '/redirecting_action'

    gaq_pushed_instructions.should have(4).items

    first_instruction, second_instruction, third_instruction, fourth_instruction = gaq_pushed_instructions

    first_instruction.should be_instruction("_setAccount")
    second_instruction.should be_instruction("_trackPageview").without_args
    third_instruction.should be_instruction('_trackEvent').with_args('from', 'redirecting', 'action')
    fourth_instruction.should track_event_from_before_filter('target_action')

    visit '/final_action'

    gaq_pushed_instructions.should have(3).items

    first_instruction, second_instruction, third_instruction = gaq_pushed_instructions

    first_instruction.should be_instruction("_setAccount")
    second_instruction.should be_instruction("_trackPageview").without_args
    third_instruction.should track_event_from_before_filter('final_action')
  end
end

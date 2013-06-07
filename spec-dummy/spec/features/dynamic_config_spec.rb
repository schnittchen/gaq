require 'spec_helper'
require 'common_spec_methods'

describe "dynamic config interpretation", dynamic: true do
  it "interprets web property id dynamically" do
    visit '/snippet_presence?wip=UA-OVERRIDE-1'

    first_instruction = gaq_pushed_instructions.first
    first_instruction.should be_instruction("_setAccount", 'UA-OVERRIDE-1')
  end

  it "interprets anonymize_ip dynamically" do
    visit '/snippet_presence?anonymize_ip=true'
    gaq_pushed_instructions[1].should be_instruction('_gat._anonymizeIp')

    visit '/snippet_presence?anonymize_ip=false'
    gaq_pushed_instructions.each do |instruction|
      instruction.should_not be_instruction('_gat._anonymizeIp')
    end
  end
end

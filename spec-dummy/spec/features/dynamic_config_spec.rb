require 'spec_helper'
require 'common_spec_methods'

describe "dynamic config interpretation" do
  it "interprets web property id dynamically" do
    visit '/snippet_presence?wip=UA-OVERRIDE-1'

    first_instruction = gaq_pushed_instructions.first
    first_instruction.should be_instruction("_setAccount", 'UA-OVERRIDE-1')
  end
end

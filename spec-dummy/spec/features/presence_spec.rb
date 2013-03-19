# encoding: utf-8

require 'spec_helper'
require 'common_spec_methods'

describe "gaq snippet presence" do
  it "renders 'gaq' in the page" do
    visit '/snippet_presence'
    expect(page.body).to have_text("_gaq")
  end

  describe "conditional examples by rails environment" do
    it "renders the configured basic web property id", :static do
      visit '/snippet_presence'
      expect(page.body).to have_text("UA-TESTSTAT-1")
    end

    it "renders the configured basic web property id", :dynamic do
      visit '/snippet_presence'
      expect(page.body).to have_text("UA-TESTDYNA-1")
    end
  end

  describe "common spec methods" do
    before { visit '/snippet_presence' }

    it "renders a CDATA containing _gaq" do
      gaq_cdata.should_not be_nil
    end

    it "starts by initializing _gaq array" do
      gaq_js_instructions.first.should == "var _gaq = _gaq || [];"
    end

    it "continues with a _gaq.push line" do
      gaq_js_instructions.second.should match(%r{\A_gaq.push\(.*\);\Z}m)
    end

    it "does not have more js lines before the snippet" do
      gaq_js_instructions.should have(2).items
    end

    it "continues with the snippet, and that's the end" do
      snippet_and_beyond.should have(1).item
      snippet_and_beyond.first.should start_with('(function()')
      snippet_and_beyond.first.should end_with('})();')
    end

    describe "pushed instructions" do
      it "pushed the expected instructions, part 1" do
        gaq_pushed_instructions.should have(3).items

        first_instruction, second_instruction, third_instruction = gaq_pushed_instructions
        first_instruction.should be_instruction("_setAccount")
        second_instruction.should be_instruction("_trackPageview").without_args
        third_instruction.should track_event_from_before_filter('snippet_presence')
      end

      it "pushed the expected instructions, part 2", :static do
        gaq_pushed_instructions.first.should be_instruction("_setAccount").with_args('UA-TESTSTAT-1')
      end
    end
  end
end

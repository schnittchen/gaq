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
      gaq_js_lines.first.should == "var _gaq = _gaq || [];"
    end
  end
end

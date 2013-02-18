# encoding: utf-8

require 'spec_helper'

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
end

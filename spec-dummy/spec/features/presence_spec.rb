# encoding: utf-8

require 'spec_helper'

describe "gaq snippet presence" do
  it "renders 'gaq' in the page" do
    visit '/snippet_presence'
    expect(page.body).to have_text("_gaq")
  end
end

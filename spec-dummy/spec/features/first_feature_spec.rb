# encoding: utf-8

require 'spec_helper'

feature "widget management" do
  scenario "creating a new widget" do
    visit '/'
    expect(page).to have_text("You’re riding Ruby on Rails")
  end
end

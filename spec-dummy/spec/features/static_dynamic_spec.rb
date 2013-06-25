require 'spec_helper'

describe "dynamic config interpretation", dynamic: true do
  it "runs this test with the correct rails env" do
    Rails.env.should be == 'test_dynamic'
  end
end

describe "dynamic config interpretation", static: true do
  it "runs this test with the correct rails env" do
    Rails.env.should be == 'test_static'
  end
end

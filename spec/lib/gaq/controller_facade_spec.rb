require 'gaq/controller_facade'

module Gaq
  describe ControllerFacade do
    let(:flash) { Object.new }
    let(:controller) do
      Struct.new(:flash).new(flash)
    end

    subject do
      described_class.new(controller)
    end

    describe '#flash' do
      it "returns controller's flash" do
        subject.flash.should be(flash)
      end
    end

    describe '#evaluate_config_lambda' do
      it "calls the lambda, passing controller, returning lambda result" do
        lmbda = ->(*args) { args }
        result = subject.evaluate_config_lambda(lmbda)
        result.should have(1).item
        result.first.should be(controller)
      end
    end
  end
end

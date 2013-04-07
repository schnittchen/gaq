require 'gaq/fetch_config_value'

module Gaq
  describe FetchConfigValue do
    let(:kls) do
      Class.new.tap do |result|
        result.send :include, described_class
        result.send :attr_accessor, :config, :controller_facade
      end
    end

    subject do
      kls.new
    end

    describe '#fetch_config_value' do
      let(:value) { Object.new }

      context "with #config result containing non-lambda in given key" do
        before do
          subject.config = { symbol: value }
        end

        it "returns the non-lambda" do
          subject.fetch_config_value(:symbol).should be(value)
        end
      end

      context "with optional param containing non-lambda in given key" do
        let(:config) do
          { symbol: value }
        end

        it "returns the non-lambda" do
          subject.fetch_config_value(:symbol, config).should be(value)
        end
      end

      context "with #config result containing lambda in given key" do
        let(:lmbda) { double }
        let(:controller_facade) { Object.new }

        before do
          subject.config = { symbol: lmbda }
          subject.controller_facade = controller_facade
        end

        it "returns the non-lambda" do
          lmbda.should_receive(:call).with(controller_facade).and_return(value)
          subject.fetch_config_value(:symbol).should be(value)
        end
      end

      context "with optional param containing lambda in given key" do
        let(:lmbda) { double }
        let(:controller_facade) { Object.new }
        let(:config) do
          { symbol: lmbda }
        end

        before do
          subject.controller_facade = controller_facade
        end

        it "returns the non-lambda" do
          lmbda.should_receive(:call).with(controller_facade).and_return(value)
          subject.fetch_config_value(:symbol, config).should be(value)
        end
      end
    end
  end
end

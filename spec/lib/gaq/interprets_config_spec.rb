require 'gaq/interprets_config'
require 'gaq/controller_facade'

require 'active_support/string_inquirer'

module Gaq
  describe InterpretsConfig do
    subject do
      Class.new do
        include InterpretsConfig

        public :interpret_config #make it accessible to tests
      end.new
    end

    let(:controller) { Object.new }

    let(:controller_facade) do
      ControllerFacade.new(controller)
    end

    it "passes strings and numbers right through" do
      subject.interpret_config(3, controller_facade).should be 3
      subject.interpret_config("foo", controller_facade).should be == "foo"
    end

    it "uses controller_facade.evaluate_config_lambda for result when value is callable" do
      value = double
      value.stub(:call) do |arg|
        arg.should be controller
        :foo
      end

      subject.interpret_config(value, controller_facade).should be :foo
    end
  end
end

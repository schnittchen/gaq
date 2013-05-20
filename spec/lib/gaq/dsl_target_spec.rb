require 'gaq/dsl_target'

require 'gaq/configuration'
require 'gaq/command_language'

module Gaq
  describe DslTarget do
    let(:target_factory) { double "target factory" }
    let(:factory_token) { double "factory token" }
    let(:new_command_proc) { double "new_command_proc" }
    let(:commands) { double "commands" }
    let(:tracker_name) { "custom tracker name" }

    shared_context with_instance_subject: true do
      subject do
        described_class.new(target_factory, factory_token, new_command_proc, commands, tracker_name)
      end
    end

    def command_expecting_tracker_name
      result = double
      result.should_receive(:tracker_name=).with(tracker_name)
      commands.should_receive(:<<).with(result).once
      result
    end

    describe "#tracker", with_instance_subject: true do
      it "delegates to target factory, passing token" do
        tracker_name = "tracker name"

        target_factory.should_receive(:target_with_tracker_name)
          .with(tracker_name, factory_token)
          .and_return(5)

        subject.tracker(tracker_name).should be 5
      end
    end

    describe "#next_request", with_instance_subject: true do
      it "delegates to target factory, passing token" do
        target_factory.should_receive(:target_for_next_request)
          .with(factory_token)
          .and_return(5)

        subject.next_request.should be 5
      end
    end

    describe "#track_event", with_instance_subject: true do
      it "foo" do
        command = command_expecting_tracker_name

        new_command_proc.should_receive(:call)
          .with(:track_event, "3", "5")
          .and_return(command)

        subject.track_event("3", "5")
      end
    end

    describe ".variable_commands_module" do
      let(:variable) do
        result = Configuration::Variable.new(4, "myvar", 2)
        result.slot.should be == 4
        result.name.should be == "myvar"
        result.scope.should be == 2
        result
      end

      subject do
        cls = Class.new(described_class)
        cls.send :include, described_class.variable_commands_module([variable])
        cls.new(target_factory, factory_token, new_command_proc, commands, tracker_name)
      end

      it "creates a variable setter that pushes a set_custom_var command" do
        command = command_expecting_tracker_name

        new_command_proc.should_receive(:call)
          .with(:set_custom_var, 4, "myvar", "value", 2)
          .and_return(command)

        subject.myvar = "value"
      end
    end
  end
end

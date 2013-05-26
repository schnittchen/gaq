require 'gaq/command_language'

module Gaq
  describe CommandLanguage do
    let(:value_coercer) { double "value coercer" }
    let(:value_preserializer) { double "value preserializer" }
    let(:value_deserializer) { double "value deserializer" }

    def null_coercing_and_serializing
      value_coercer.stub(:call) { |type, value| value }
      value_preserializer.stub(:call) { |type, value| value }
    end

    subject do
      result = described_class.new
      result.value_coercer = value_coercer
      result.value_preserializer = value_preserializer
      result.value_deserializer = value_deserializer
      result
    end

    before do
      subject.knows_command(:foo) do |desc|
        desc.signature = [String]
        desc.name = "_myFooCommand"
      end if example.metadata[:foo_command]

      subject.knows_command(:bar) do |desc|
        desc.signature = [String, Integer]
        desc.name = "_myBarCommand"
      end if example.metadata[:bar_command]
    end

    describe ".new_command", foo_command: true do
      it "returns a command with expected identifier, name and coerced params" do
        value_coercer.should_receive(:call).with(String, "string").and_return "coerced string"

        command = subject.new_command(:foo, "string")

        command.identifier.should be == :foo
        command.name.should be == "_myFooCommand"
        command.params.should be == ["coerced string"]
      end
    end

    shared_examples ".commands_to_flash_items behaves" do
      let(:flash_data_item) do
        flash_items = subject.commands_to_flash_items([command])
        flash_items.should have(1).item
        flash_items.first
      end

      context "with a command accepting two parameters", bar_command: true do
        let(:command) do
          command = CommandLanguage::Command.new
          command.identifier = :bar
          command.name = "_myBarCommand"
          command.params = []
          command
        end

        it "preserializes params into data items" do
          value_preserializer.should_receive(:call).with(String, "first coerced string").and_return "first preserialized string"
          value_preserializer.should_receive(:call).with(Integer, "second coerced string").and_return "second preserialized string"

          command.params << "first coerced string" << "second coerced string"

          flash_data_item.should have(3).items
          flash_data_item[1].should be == "first preserialized string"
          flash_data_item[2].should be == "second preserialized string"
        end

        it "preserializes only given params into data item even if less params given than signature length" do
          value_preserializer.should_receive(:call).with(String, "first coerced string").and_return "first preserialized string"

          command.params << "first coerced string"

          flash_data_item.should have(2).items
          flash_data_item[1].should be == "first preserialized string"
        end
      end

      context "with a command accepting one parameter", foo_command: true do
        let(:command) do
          command = CommandLanguage::Command.new
          command.identifier = :foo
          command.name = "_myFooCommand"
          command.params = ["coerced string"]
          command
        end

        it "sets the first flash item's first item to the command name (no target set)" do
          null_coercing_and_serializing

          flash_data_item.should have(2).items
          flash_data_item.first.should be == "_myFooCommand"
        end

        it "sets the first flash item's first item to the command name (target set)" do
          null_coercing_and_serializing

          command.tracker_name = "tracker"

          flash_data_item.should have(2).items
          flash_data_item.first.should be == "tracker._myFooCommand"
        end
      end
    end

    describe ".commands_to_flash_items" do
      let(:result) do
        subject.commands_to_flash_items([command])
      end

      it_should_behave_like ".commands_to_flash_items behaves"
    end

    describe ".commands_to_segments_for_to_json" do
      let(:result) do
        subject.commands_to_segments_for_to_json([command])
      end

      it_should_behave_like ".commands_to_flash_items behaves"
    end

    describe ".sort_commands" do
      it "properly sorts commands"
    end

    describe ".commands_from_flash_items", foo_command: true, bar_command: true do
      it "correctly detects the command" do
        flash_items = [
          ["_myFooCommand"],
          ["_myBarCommand"]
        ]
        commands = subject.commands_from_flash_items(flash_items)

        commands.should have(2).items

        command = commands.first
        command.identifier.should be == :foo
        command.name.should be == '_myFooCommand'

        command = commands.last
        command.identifier.should be == :bar
        command.name.should be == '_myBarCommand'
      end

      it "deserializes parameters" do
        params = ["first preserialized string", "second preserialized string"]

        value_deserializer.should_receive(:call).with(String, params.first).and_return("first deserialized string")
        value_deserializer.should_receive(:call).with(Integer, params.last).and_return("second deserialized string")

        flash_item = ["_myBarCommand", *params]
        commands = subject.commands_from_flash_items([flash_item])

        commands.should have(1).item
        command = commands.first

        command.params.should be == ["first deserialized string", "second deserialized string"]
      end

      it "sets tracker name to nil when no explicit tracker given" do
        flash_item = ["_myFooCommand"]
        commands = subject.commands_from_flash_items([flash_item])

        commands.should have(1).item
        command = commands.first

        command.tracker_name.should be_nil
      end

      it "correctly sets present tracker name" do
        flash_item = ["my_tracker._myFooCommand"]
        commands = subject.commands_from_flash_items([flash_item])

        commands.should have(1).item
        command = commands.first

        command.tracker_name.should be == "my_tracker"
      end
    end
  end
end

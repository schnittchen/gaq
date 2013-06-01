require 'gaq/command_language'

module Gaq
  describe CommandLanguage do
    let(:value_coercer) { double "value coercer" }

    def null_coercing
      value_coercer.stub(:call) { |type, value| value }
    end

    subject do
      result = described_class.new
      result.value_coercer = value_coercer
      result
    end

    let(:descriptors) { {} }

    before do
      subject.knows_command(:foo) do |desc|
        desc.signature = [String]
        desc.name = "_myFooCommand"
        descriptors[:foo] = desc
      end if example.metadata[:foo_command]

      subject.knows_command(:bar) do |desc|
        desc.signature = [String, Integer]
        desc.name = "_myBarCommand"
        desc.sort_slot = 1
        descriptors[:bar] = desc
      end if example.metadata[:bar_command]

      subject.knows_command(:baz) do |desc|
        desc.signature = []
        desc.name = "_myBazCommand"
        desc.sort_slot = 0
        descriptors[:baz] = desc
      end if example.metadata[:baz_command]
    end

    RSpec::Matchers.define :be_identified_as do |identifier|
      match do |command|
        command.descriptor.identifier.equal? identifier
      end
    end

    describe ".new_command" do
      it "returns a properly identified and named command", foo_command: true do
        null_coercing

        command = subject.new_command(:foo, "string")

        command.should be_identified_as(:foo)
        command.name.should be == "_myFooCommand"
      end

      it "passes params through value coercer", foo_command: true do
        value_coercer.should_receive(:call).with(String, "string").and_return "coerced string"

        command = subject.new_command(:foo, "string")

        command.params.should be == ["coerced string"]
      end

      it "passes only given params through coercer, even if less than signature length", bar_command: true do
        value_coercer.should_receive(:call).with(String, "string").and_return "coerced string"

        command = subject.new_command(:bar, "string")

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
          command.descriptor = descriptors[:bar]
          command.name = "_myBarCommand"
          command.params = []
          command
        end

        it "adds params to data items" do
          command.params << "first param" << "second param"

          flash_data_item.should have(3).items
          flash_data_item[1].should be == "first param"
          flash_data_item[2].should be == "second param"
        end

        it "adds only as many params as signature length" do
          command.params << "first param"

          flash_data_item.should have(2).items
          flash_data_item[1].should be == "first param"
        end
      end

      context "with a command accepting one parameter", foo_command: true do
        let(:command) do
          command = CommandLanguage::Command.new
          command.descriptor = descriptors[:foo]
          command.name = "_myFooCommand"
          command.params = ["param"]
          command
        end

        it "sets the first flash item's first item to the command name (no target set)" do
          null_coercing

          flash_data_item.should have(2).items
          flash_data_item.first.should be == "_myFooCommand"
        end

        it "sets the first flash item's first item to the command name (target set)" do
          null_coercing

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
      def assert_order(commands)
        commands[0].should be_identified_as(:baz)
        commands[1].should be_identified_as(:bar)
        commands[2].should be_identified_as(:foo)
      end

      it "sorts commands by sort_slot, missing sort_slot values last",
          foo_command: true, bar_command: true, baz_command: true do
        commands = [
          subject.new_command(:foo),
          subject.new_command(:bar),
          subject.new_command(:baz)
        ]

        subject.sort_commands(commands)
        assert_order(commands)

        commands = [
          subject.new_command(:bar),
          subject.new_command(:foo),
          subject.new_command(:baz)
        ]

        subject.sort_commands(commands)
        assert_order(commands)
      end
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
        command.should be_identified_as(:foo)
        command.name.should be == '_myFooCommand'

        command = commands.last
        command.should be_identified_as(:bar)
        command.name.should be == '_myBarCommand'
      end

      it "sets command's params to remaining segments from flash item" do
        flash_item = ["_myBarCommand", "first param", "second param"]

        commands = subject.commands_from_flash_items([flash_item])

        commands.should have(1).item
        command = commands.first

        command.params.should be == ["first param", "second param"]
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

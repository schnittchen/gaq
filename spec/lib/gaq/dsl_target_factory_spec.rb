require 'gaq/dsl_target_factory'

require 'gaq/class_cache'

module Gaq
  describe DslTargetFactory do
    let(:flash_commands_adapter) { Object.new }
    let(:immediate_commands) { Object.new }
    let(:new_command_proc) { Object.new }
    let(:variables) { Object.new }

    let(:class_cache) do
      ClassCache.new
    end

    let(:target_base_class) do
      Class.new do
        attr_reader :target_factory, :factory_token, :new_command_proc, :commands, :tracker_name

        def initialize(target_factory, factory_token, new_command_proc, commands, tracker_name)
          @target_factory, @factory_token, @new_command_proc, @commands, @tracker_name =
            target_factory, factory_token, new_command_proc, commands, tracker_name
        end

        class << self
          def builds_variable_commands_module(&block)
            @block = block
          end

          def variable_commands_module(*args)
            @block.call(*args)
          end
        end

        #default implementation for examples not concerned about variables
        self.builds_variable_commands_module { Module.new }
      end
    end

    subject do
      result = described_class.new(class_cache, flash_commands_adapter, immediate_commands, new_command_proc, variables)
      result.target_base_class = target_base_class
      result
    end

    describe "targets" do
      shared_context "common initalization of target" do
        it "passes itself as target factory" do
          target.target_factory.should be subject
        end

        it "passes the new_command_proc through" do
          target.new_command_proc.should be new_command_proc
        end
      end

      shared_context immediate_commands: true do
        it "passes immediate_commands as commands" do
          target.commands.should be immediate_commands
        end
      end

      shared_context flash_commands: true do
        it "passes flash_commands_adapter as commands" do
          target.commands.should be flash_commands_adapter
        end
      end

      shared_context default_tracker: true do
        it "passes nil as the tracker name" do
          target.tracker_name.should be_nil
        end
      end

      shared_context custom_tracker: true do
        it "passes nil as the tracker name" do
          target.tracker_name.should be == "tracker name"
        end
      end

      describe "#root_target", immediate_commands: true, default_tracker: true do
        let(:target) { subject.root_target }

        include_context "common initalization of target"
      end

      let(:root_token) do
        subject.root_target.factory_token
      end

      describe "#target_with_tracker_name" do
        it "tolerates both strings and symbols as tracker names" do
          subject.target_with_tracker_name("tracker name", root_token).tracker_name.should be ==
            subject.target_with_tracker_name(:"tracker name", root_token).tracker_name
        end
      end

      describe "#target_with_tracker_name (token is root token)", immediate_commands: true, custom_tracker: true do
        let(:target) { subject.target_with_tracker_name("tracker name", root_token) }

        include_context "common initalization of target"
      end

      describe "#target_for_next_request (token is root token)", flash_commands: true, default_tracker: true do
        let(:target) { subject.target_for_next_request(root_token) }

        include_context "common initalization of target"
      end

      describe "#target_with_tracker_name (token is from #target_for_next_request)", flash_commands: true, custom_tracker: true do
        let(:target) do
          token = subject.target_for_next_request(root_token).factory_token
          subject.target_with_tracker_name("tracker name", token)
        end

        include_context "common initalization of target"
      end

      describe "#target_with_tracker_name (token is from #target_with_tracker_name)", custom_tracker: true, immediate_commands: true do
        let(:target) do
          token = subject.target_with_tracker_name("foo", root_token).factory_token
          subject.target_with_tracker_name("tracker name", token)
        end

        include_context "common initalization of target"
      end

      describe "#target_for_next_request (token is from #target_with_tracker_name)", custom_tracker: true, flash_commands: true do
        let(:target) do
          token = subject.target_with_tracker_name("tracker name", root_token).factory_token
          subject.target_for_next_request(token)
        end

        include_context "common initalization of target"
      end
    end

    describe "variables" do
      let(:variables_module) { Module.new }

      before do
        target_base_class.builds_variable_commands_module do |*args|
          args.should have(1).argument
          args.first.should be variables
          variables_module
        end
      end

      it "includes the variables module into the target's class" do
        subject.root_target.should be_a_kind_of(variables_module)
      end
    end
  end
end

require 'gaq/controller_handle'
require 'gaq/configuration'
require 'gaq/class_cache'

RSpec::Matchers.define :command_segments do
  match do |segments|
    next false unless segments.is_a?(Array) and segments.length >= 1
    first_segment = segments.first
    command, tracker = first_segment.split('.', 2).reverse

    (!@first_segment || first_segment == @first_segment) &&
      (!@tracker_name || tracker.to_s == @tracker_name)
  end

  chain :starting_with do |first_segment|
    @first_segment = first_segment
  end

  chain :for_tracker do |tracker_name|
    @tracker_name = tracker_name.to_s
  end

  chain :for_default_tracker do
    @tracker_name = ''
  end
end

describe "custom matcher" do
  it "detects commands" do
    [['foo']].should include(command_segments.starting_with('foo'))
    [['foo']].should_not include(command_segments.starting_with('bar'))
    [['tracker.foo']].should_not include(command_segments.starting_with('foo'))
    [['tracker.foo']].should include(command_segments.starting_with('tracker.foo'))

    [['foo']].should include(command_segments.for_default_tracker)
    [['foo']].should_not include(command_segments.for_tracker('tracker'))
    [['tracker.foo']].should include(command_segments.for_tracker('tracker'))
    [['tracker.foo']].should_not include(command_segments.for_default_tracker)
  end
end

module Gaq
  describe ControllerHandle do
    describe "#finalized_commands_as_segments" do
      # This is more like an integration test. Many things are stubbed by real representatives,
      # e.g. a real CommandLanguage object (because that's easier).
      # The purpose of these examples is to assert what commands are rendered and what are
      # placed in the flash, under different circumstances, namely,
      # configurations and relevant data initially found in flash.

      # Assertions are made against
      # * #finalized_commands_as_segments results (see let(:result)) and
      # * commands_pushed_to_flash
      # Initial flash input is placed in
      # * commands_from_flash
      # For test convenience, all three use the same format, namely an array of commands
      # represented as command segments. The language is used for the necessary conversion.
      # Emptiness of commands_pushed_to_flash is automatically asserted unless the
      # push_to_flash: true metadata is present.

      # The result array is implicitly checked to comply to certain ordering assumptions (fex.
      # a tracker must be initialized with _setAccount before anything else is done with it).
      # See let(:result) for details.

      let(:stubbed_controller_facade) { double "controller facade" }

      let(:stubbed_language) do
        # we use the actual implementation, given that this spec is at the highest level of all
        result = CommandLanguage.new
        CommandLanguage.declare_language_on(result)
        CommandLanguage.define_transformations_on(result)
        result
      end

      let(:stubbed_configuration) do
        Configuration.new
      end

      # convenience. think "config.gaq", so rails_config.track_event would be config.gaq.track_event in the real world
      let(:rails_config) { stubbed_configuration.rails_config }

      let(:commands_from_flash) { [] }
      let(:commands_pushed_to_flash) { [] }

      let(:stubbed_flash_commands_adapter) do
        result = double("flash_commands_adapter")

        # for test convenience, convert between plain "segments" arrays and proper command objects
        # this depends on features from language

        result.stub(:commands_from_flash) do
          stubbed_language.commands_from_flash_items(commands_from_flash)
        end

        result.stub(:<<) do |item|
          item = stubbed_language.commands_to_flash_items([item]).first
          commands_pushed_to_flash << item
        end

        result
      end

      after do
        # automatically assert that nothing got pushed to flash storage unless metadata tagged
        commands_pushed_to_flash.should be_empty \
          unless example.metadata[:push_to_flash]
      end

      subject do
        described_class.new(stubbed_controller_facade, stubbed_language, ClassCache.new, stubbed_configuration).tap do |result|
          result.flash_commands_adapter = stubbed_flash_commands_adapter
        end
      end

      let(:result) do
        subject.finalized_commands_as_segments
      end

      let(:order_asserter_class) do
        # We need to do a bunch of assertions that are hard to express in rspec proper.
        # This class does the heavy lifting. It is tested below!
        Class.new do
          def initialize(result, context)
            @result = result
            @context = context
          end

          def do_the_assertions
            ## overall order assumptions

            # renders _gat._anonymizeIp before any _trackPageview, _setCustomVar or _trackEvent"
            any_occurrence_of('_anonymizeIp').should \
              precede(any_occurrence_of('_trackPageview'))
            any_occurrence_of('_anonymizeIp').should \
              precede(any_occurrence_of('_setCustomVar'))
            any_occurrence_of('_anonymizeIp').should \
              precede(any_occurrence_of('_trackEvent'))

            ## per tracker order assumptions

            # it rendes _setAccount before _trackPageview, _setCustomVar or _trackEvent
            tracker_occurrences_of('_setAccount').should \
              precede(tracker_occurrences_of('_trackPageview'))
            tracker_occurrences_of('_setAccount').should \
              precede(tracker_occurrences_of('_setCustomVar'))
            tracker_occurrences_of('_setAccount').should \
              precede(tracker_occurrences_of('_trackEvent'))

            # it renders _setCustomVar before _trackEvent
            tracker_occurrences_of('_setCustomVar').should \
              precede(tracker_occurrences_of('_trackEvent'))
          end

          def self_test
            @result = [
              ['cmd1'], ['cmd2'], ['tracker.cmd1'], ['tracker.cmd2'],
              ['cmd3'], ['cmd4'], ['tracker.cmd5']
            ]

            tracker_occurrences_of('cmd1').should \
              precede(tracker_occurrences_of('cmd2'))

            tracker_occurrences_of('cmd2').should_not \
              precede(tracker_occurrences_of('cmd1'))

            any_occurrence_of('cmd3').should \
              precede(any_occurrence_of('cmd4'))

            any_occurrence_of('cmd4').should_not \
              precede(any_occurrence_of('cmd3'))

            any_occurrence_of('cmd3').should \
              precede(any_occurrence_of('cmd5'))

            any_occurrence_of('cmd5').should_not \
              precede(any_occurrence_of('cmd3'))
          end

          private

          def precede(following)
            @context.satisfy do |preceding|
              preceding.all? do |tracker_name, indices|
                following_indices = following[tracker_name]
                [*indices, -1].max < [*following_indices, 2**31].min
              end
            end
          end

          def tracker_occurrences_of(command_name)
            command_occurrences_with_matching_tracker_name(command_name) do |tracker_name|
              tracker_name != :any
            end
            # preprocessed_result[command_name].select { |tracker_name, _| tracker_name != :any }
          end

          def any_occurrence_of(command_name)
            command_occurrences_with_matching_tracker_name(command_name) do |tracker_name|
              tracker_name == :any
            end
            # preprocessed_result[command_name].select { |tracker_name, _| tracker_name == :any }
          end

          def command_occurrences_with_matching_tracker_name(command_name)
            analyzed_result[command_name].select { |tracker_name, _| yield tracker_name }
          end

          def analyzed_result
            ar = Hash.new do |hash, command_name|
              hash[command_name] = Hash.new { |h, tracker_name| h[tracker_name] = [] }
            end

            @result.map(&:first).each_with_index do |first_segment, index|
              command_name, tracker_name = first_segment.split('.', 2).reverse

              per_command = ar[command_name]
              per_command[tracker_name] << index
              per_command[:any] << index
            end

            ar
          end
        end
      end

      describe "order asserter mechanism" do
        # the order_asserter_class does heavy lifting and deserves being tested!

        it "does what we expect" do
          order_asserter_class.new(nil, self).self_test
        end
      end

      after do
        # automatically assert order assumptions for each example
        order_asserter_class.new(result, self).do_the_assertions
        # this way we don't forget.
      end

      let(:root_target) { subject.root_target }

      shared_context declare_var: true do
        before do
          rails_config.declare_variable :var, scope: 3, slot: 0
        end
      end

      context "without further configuration" do
        it "returns _setAccount (unset wpi) and _trackPageview for default tracker" do
          result.should have(2).items
          result.should include(["_setAccount", "UA-XUNSET-S"])
          result.should include(["_trackPageview"])
        end
      end

      context "with config.gaq.anonymize_ip = true" do
        before do
          rails_config.anonymize_ip = true
        end

        it "renders '_gat._anonymizeIp" do
          result.should include(["_gat._anonymizeIp"])
        end
      end

      describe "default tracker configuration effect" do
        before do
          rails_config.web_property_id = 'UA-TEST23-5'
        end

        it "renders a correct _setAccount" do
          result.should include(["_setAccount", 'UA-TEST23-5'])
        end

        it "renders a _trackPageview by default" do
          result.should include(["_trackPageview"])
        end

        context "config.gaq.track_pageview = false" do
          before do
            rails_config.track_pageview = false
          end

          it "does not render a _trackPageview for the tracker" do
            result.should_not include(["_trackPageview"])
          end
        end
      end

      describe "effect of tracker commands issued on default tracker" do
        describe "gaq.track_event 'category', 'action', 'label'" do
          before do
            root_target.track_event 'category', 'action', 'label'
          end

          it "renders the _trackEvent" do
            result.should include(["_trackEvent", "category", "action", "label"])
          end
        end

        # more here when implemented...
      end

      describe "effect of tracker commands issued on default tracker .next_request" do
        context "gaq.next_request.track_event 'category', 'action', 'label'", push_to_flash: true do
          before do
            root_target.next_request.track_event 'category', 'action', 'label'
          end

          it "does not render the _trackEvent" do
            result.should_not include command_segments.starting_with('_trackEvent')
          end

          it "pushes the _trackEvent to flash storage" do
            commands_pushed_to_flash.should be == [
              ["_trackEvent", "category", "action", "label"]
            ]
          end
        end

        # more here when implemented...
      end

      context "with a variable declared", declare_var: true do
        it "returns nothing in addition" do
          result.should have(2).items
          result.should include(["_setAccount", "UA-XUNSET-S"])
          result.should include(["_trackPageview"])
        end

        context "after assigning to variable" do
          before do
            root_target.var = "blah"
          end

          it "renders the _setCustomVar" do
            result.should include(["_setCustomVar", 0, "var", "blah", 3])
          end

          context "gaq.track_event 'category', 'action', 'label'" do
            before(:each) do
              root_target.track_event 'category', 'action', 'label'
            end

            it "renders the _trackEvent in addition, maintaining correct order" do
              # order assertion is not here, see preamble.
              result.should include(["_setCustomVar", 0, "var", "blah", 3])
              result.should include(["_trackEvent", "category", "action", "label"])
            end
          end
        end

        context "after assigning to variable on gaq.next_request", push_to_flash: true do
          before do
            root_target.next_request.var = "blah"
          end

          it "does not render a _setCustomVar" do
            result.should_not include(command_segments.starting_with('_setCustomVar'))
          end

          it "pushes the _setCustomVar onto the flash storage" do
            commands_pushed_to_flash.should be == [
              ["_setCustomVar", 0, "var", "blah", 3]
            ]
          end
        end
      end

      context "with commands stored in flash" do
        before do
          commands_from_flash << ["_trackEvent", "last_cat", "last_action", "last_label"]
          commands_from_flash << ["_setCustomVar", 0, "var", "blah", 3]
        end

        it "renders these" do
          result.should include(["_setCustomVar", 0, "var", "blah", 3])
          result.should include(["_trackEvent", "last_cat", "last_action", "last_label"])
        end

        context "gaq.next_request.track_event 'category', 'action', 'label'", push_to_flash: true do
          before(:each) do
            root_target.next_request.track_event 'category', 'action', 'label'
          end

          it "does not render that in addition" do
            result.should_not include(["_trackEvent", "category", "action", "label"])
          end

          it "pushes that on the flash store instead" do
            commands_pushed_to_flash.should be == [
              ["_trackEvent", "category", "action", "label"]
            ]
          end
        end

        context "with a variable declared", declare_var: true do
          context "after assigning to same variable again" do
            before do
              root_target.var = "blubb"
            end

            it "renders both _setCustomVar, in order" do
              first_set_custom_var = ["_setCustomVar", 0, "var", "blah", 3]
              second_set_custom_var = ["_setCustomVar", 0, "var", "blubb", 3]

              result.should include(first_set_custom_var)
              result.should include(second_set_custom_var)
              result.index(first_set_custom_var).should be <
                result.index(second_set_custom_var)
            end
          end

        end
      end

      context "with a custom tracker" do
        before do
          rails_config.additional_trackers = ["foo"]
        end

        it "renders a _setAccount for the additional tracker" do
          result.should include(['foo._setAccount', "UA-XUNSET-S"])
        end

        it "renders a _trackPageview for the tracker" do
          result.should include(["foo._trackPageview"])
        end

        context "configured not to track pageviews" do
          before do
            rails_config.tracker(:foo).track_pageview = false
          end

          it "does not render a _trackPageview for the tracker" do
            result.should_not include(["foo._trackPageview"])
          end
        end

        context "after gaq[:foo].track_event 'category', 'action', 'label'" do
          before do
            root_target["foo"].track_event 'category', 'action', 'label'
          end

          it "renders the _trackEvent" do
            result.should include(["foo._trackEvent", "category", "action", "label"])
          end
        end
      end

      it "fails when an undeclared tracker is accessed from a target like gaq[:bogus]" do
        expect {
          root_target[:bogus]
        }.to raise_exception
      end

      context "with commands stored in flash referencing a nonexistend tracker" do
        before do
          commands_from_flash << ["nonexistent._trackEvent", "last_cat", "last_action", "last_label"]
        end

        it "does not raise an exception" do
          result
        end
      end
    end
  end
end

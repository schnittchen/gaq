require 'gaq/controller_handle'
require 'gaq/configuration'
require 'gaq/class_cache'

module Gaq
  describe ControllerHandle do
    describe "#finalized_commands_as_segments" do
      let(:controller_facade) { double "controller facade" }

      let(:language) do
        result = CommandLanguage.new
        CommandLanguage.declare_language_on(result)
        CommandLanguage.define_transformations_on(result)
        result
      end

      let(:class_cache) { ClassCache.new }
      let(:config) do
        Configuration.new
      end
      let(:rails_config) { config.rails_config }

      let(:commands_from_flash) { [] }

      let(:flash_commands_adapter) do
        result = double("flash_commands_adapter")
        result.stub(:commands_from_flash) { commands_from_flash }
        result
      end

      subject do
        described_class.new(controller_facade, language, class_cache, config).tap do |result|
          result.flash_commands_adapter = flash_commands_adapter
        end
      end

      let(:result) do
        subject.finalized_commands_as_segments
      end

      let(:root_target) { subject.root_target }

      context "without further configuration" do
        it "returns _setAccount (unset wpi) and _trackPageview for default tracker" do
          result.should be == [
            ["_setAccount", "UA-XUNSET-S"],
            ["_trackPageview"]
          ]
        end
      end

      context "configuring default tracker" do
        context "config.gaq.track_pageview = false" do
          before do
            rails_config.track_pageview = false
          end

          it "does not render _trackPageview for default tracker" do
            pending
            result.should be == [
              ["_setAccount", "UA-XUNSET-S"]
            ]
          end
        end

        context "config.gaq.web_property_id=" do
          before do
            rails_config.web_property_id = 'UA-TEST23-5'
          end

          it "renders _setAccount with the given id" do
            result.should be == [
              ["_setAccount", 'UA-TEST23-5'],
              ["_trackPageview"]
            ]
          end
        end
      end

      context "with tracker commands issued on default tracker" do
        context "gaq.track_event 'category', 'action', 'label'" do
          before do
            root_target.track_event 'category', 'action', 'label'
          end

          it "renders the _trackEvent" do
            result.should be == [
              ["_setAccount", "UA-XUNSET-S"],
              ["_trackPageview"],
              ["_trackEvent", "category", "action", "label"]
            ]
          end
        end
      end
    end
  end
end

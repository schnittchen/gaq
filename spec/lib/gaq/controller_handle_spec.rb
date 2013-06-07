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

      let(:config) do
        Configuration.new
      end
      let(:rails_config) { config.rails_config }

      let(:commands_from_flash) { [] }
      let(:commands_pushed_to_flash) { [] }

      let(:flash_commands_adapter) do
        result = double("flash_commands_adapter")

        # for test convenience, convert between plain "segments" arrays and proper command objects
        # this depends on features from language

        result.stub(:commands_from_flash) do
          language.commands_from_flash_items(commands_from_flash)
        end

        result.stub(:<<) do |item|
          item = language.commands_to_flash_items([item]).first
          commands_pushed_to_flash << item
        end

        result
      end

      after do
        commands_pushed_to_flash.should be_empty \
          unless example.metadata[:push_to_flash]
      end

      subject do
        described_class.new(controller_facade, language, ClassCache.new, config).tap do |result|
          result.flash_commands_adapter = flash_commands_adapter
        end
      end

      let(:result) do
        subject.finalized_commands_as_segments
      end

      let(:root_target) { subject.root_target }

      shared_context declare_var: true do
        before do
          rails_config.declare_variable :var, scope: 3, slot: 0
        end
      end

      context "without further configuration" do
        it "returns _setAccount (unset wpi) and _trackPageview for default tracker" do
          result.should be == [
            ["_setAccount", "UA-XUNSET-S"],
            ["_trackPageview"]
          ]
        end
      end

      context "with config.gaq.anonymize_ip = true" do
        before do
          rails_config.anonymize_ip = true
        end

        it "renders '_gat._anonymizeIp" do
          result.should be == [
            ["_setAccount", "UA-XUNSET-S"],
            ["_gat._anonymizeIp"],
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

      context "with tracker commands issued on default tracker .next_request" do
        context "gaq.next_request.track_event 'category', 'action', 'label'", push_to_flash: true do
          before do
            root_target.next_request.track_event 'category', 'action', 'label'
          end

          it "renders the _trackEvent" do
            result.should be == [
              ["_setAccount", "UA-XUNSET-S"],
              ["_trackPageview"]
            ]

            commands_pushed_to_flash.should be == [
              ["_trackEvent", "category", "action", "label"]
            ]
          end
        end
      end

      context "with a variable declared", declare_var: true do
        it "returns nothing in addition" do
          result.should be == [
            ["_setAccount", "UA-XUNSET-S"],
            ["_trackPageview"]
          ]
        end

        context "after assigning to variable" do
          before do
            root_target.var = "blah"
          end

          it "renders the _setCustomVar" do
            result.should be == [
              ["_setAccount", "UA-XUNSET-S"],
              ["_trackPageview"],
              ["_setCustomVar", 0, "var", "blah", 3]
            ]
          end

          context "gaq.track_event 'category', 'action', 'label'" do
            before(:each) do
              root_target.track_event 'category', 'action', 'label'
            end

            it "renders the _setCustomVar before the _trackEvent" do
              result.should be == [
                ["_setAccount", "UA-XUNSET-S"],
                ["_trackPageview"],
                ["_setCustomVar", 0, "var", "blah", 3],
                ["_trackEvent", "category", "action", "label"]
              ]
            end
          end

          context "gaq.next_request.track_event 'category', 'action', 'label'", push_to_flash: true do
            before(:each) do
              root_target.next_request.track_event 'category', 'action', 'label'
            end

            it "renders the _setCustomVar before the _trackEvent" do
              result.should be == [
                ["_setAccount", "UA-XUNSET-S"],
                ["_trackPageview"],
                ["_setCustomVar", 0, "var", "blah", 3],
              ]

              commands_pushed_to_flash.should be == [
                ["_trackEvent", "category", "action", "label"]
              ]
            end
          end

          context "both track_event and variable assignment on gaq.next_request", push_to_flash: true do
            before(:each) do
              root_target.next_request.track_event 'category', 'action', 'label'
              root_target.next_request.var = "foo"
            end

            it "pushes the _setCustomVar and the _trackEvent onto the flash storage" do
              result.should be == [
                ["_setAccount", "UA-XUNSET-S"],
                ["_trackPageview"],
                ["_setCustomVar", 0, "var", "blah", 3],
              ]

              commands_pushed_to_flash.should be == [
                ["_trackEvent", "category", "action", "label"],
                ["_setCustomVar", 0, "var", "foo", 3],
              ]
            end
          end

        end
      end

      context "with commands stored in flash" do
        before do
          commands_from_flash << ["_trackEvent", "last_cat", "last_action", "last_label"]
          commands_from_flash << ["_setCustomVar", 0, "var", "blah", 3]
        end

        it "renders these" do
          result.should be == [
            ["_setAccount", "UA-XUNSET-S"],
            ["_trackPageview"],
            ["_setCustomVar", 0, "var", "blah", 3],
            ["_trackEvent", "last_cat", "last_action", "last_label"]
          ]
        end

        context "gaq.track_event 'category', 'action', 'label'" do
          before(:each) do
            root_target.track_event 'category', 'action', 'label'
          end

          it "renders that in addition" do
            result.should be == [
              ["_setAccount", "UA-XUNSET-S"],
              ["_trackPageview"],
              ["_setCustomVar", 0, "var", "blah", 3],
              ["_trackEvent", "last_cat", "last_action", "last_label"],
              ["_trackEvent", "category", "action", "label"]
            ]
          end
        end

        context "gaq.next_request.track_event 'category', 'action', 'label'", push_to_flash: true do
          before(:each) do
            root_target.next_request.track_event 'category', 'action', 'label'
          end

          it "does not render that in addition" do
            result.should be == [
              ["_setAccount", "UA-XUNSET-S"],
              ["_trackPageview"],
              ["_setCustomVar", 0, "var", "blah", 3],
              ["_trackEvent", "last_cat", "last_action", "last_label"],
            ]

            commands_pushed_to_flash.should be == [
              ["_trackEvent", "category", "action", "label"]
            ]
          end
        end

        context "with a variable declared", declare_var: true do
          it "returns nothing in addition" do
            result.should be == [
              ["_setAccount", "UA-XUNSET-S"],
              ["_trackPageview"],
              ["_setCustomVar", 0, "var", "blah", 3],
              ["_trackEvent", "last_cat", "last_action", "last_label"],
            ]
          end

          context "after assigning to variable" do
            before do
              root_target.var = "blubb"
            end

            it "renders both _setCustomVar, in order" do
              result.should be == [
                ["_setAccount", "UA-XUNSET-S"],
                ["_trackPageview"],
                ["_setCustomVar", 0, "var", "blah", 3],
                ["_setCustomVar", 0, "var", "blubb", 3],
                ["_trackEvent", "last_cat", "last_action", "last_label"]
              ]
            end

            context "gaq.track_event 'category', 'action', 'label'" do
              before do
                root_target.track_event 'category', 'action', 'label'
              end

              it "renders the _trackEvent in addition" do
                result.should be == [
                  ["_setAccount", "UA-XUNSET-S"],
                  ["_trackPageview"],
                  ["_setCustomVar", 0, "var", "blah", 3],
                  ["_setCustomVar", 0, "var", "blubb", 3],
                  ["_trackEvent", "last_cat", "last_action", "last_label"],
                  ["_trackEvent", "category", "action", "label"]
                ]
              end
            end

            context "gaq.next_request.track_event 'category', 'action', 'label'", push_to_flash: true do
              before do
                root_target.next_request.track_event 'category', 'action', 'label'
              end

              it "renders the _trackEvent in addition" do
                result.should be == [
                  ["_setAccount", "UA-XUNSET-S"],
                  ["_trackPageview"],
                  ["_setCustomVar", 0, "var", "blah", 3],
                  ["_setCustomVar", 0, "var", "blubb", 3],
                  ["_trackEvent", "last_cat", "last_action", "last_label"],
                ]

                commands_pushed_to_flash.should be == [
                  ["_trackEvent", "category", "action", "label"]
                ]
              end
            end
          end

        end
      end

      context "with a custom tracker" do
        before do
          rails_config.additional_trackers = ["foo"]
        end

        it "does not render a _setAccount for the additional tracker" do
          result.should be == [
            ["_setAccount", "UA-XUNSET-S"],
            ["_trackPageview"]
          ]
        end

        context "after gaq[:foo].track_event 'category', 'action', 'label'" do
          before do
            root_target["foo"].track_event 'category', 'action', 'label'
          end

          it "renders _setAccount, _trackPageview and _trackEvent for that tracker" do
            result.should be == [
              ["_setAccount", "UA-XUNSET-S"],
              ["foo._setAccount", "UA-XUNSET-S"],
              ["_trackPageview"],
              ["foo._trackPageview"],
              ["foo._trackEvent", "category", "action", "label"]
            ]
          end

          context "with config.gaq.tracker(:foo).track_pageview = false" do
            before do
              rails_config.tracker(:foo).track_pageview = false
            end

            it "does not render _trackPageview, but _setAccount and _trackEvent for that tracker" do
              result.should be == [
                ["_setAccount", "UA-XUNSET-S"],
                ["foo._setAccount", "UA-XUNSET-S"],
                ["_trackPageview"],
                ["foo._trackEvent", "category", "action", "label"]
              ]
            end
          end
        end
      end

      it "fails when an undeclared tracker is accessed from a target like gaq[:bogus]" do
        expect {
          root_target[:bogus]
        }.to raise_exception
      end
    end
  end
end

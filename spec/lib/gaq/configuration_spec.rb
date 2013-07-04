require 'gaq/configuration'

require 'gaq/interprets_config'
require 'active_support/string_inquirer'

module Gaq
  describe Configuration do
    let(:rails) { subject.rails_config }

    describe "rails exposed config object" do
      describe ".declare_variable" do
        describe "variable setup" do
          let(:variable) do
            subject.variables.should have(1).variable
            subject.variables["my_variable"]
          end

          it "sets up variable name and slot correctly" do
            rails.declare_variable("my_variable", slot: 2)

            variable.name.should be == "my_variable"
            variable.slot.should be 2
          end

          it "default to scope code 3" do
            rails.declare_variable("my_variable", slot: 1)

            variable.scope.should be 3
          end

          it "correctly sets up scope, given as symbol" do
            rails.declare_variable("my_variable", slot: 1, scope: :visitor)

            variable.scope.should be 1
          end

          it "correctly sets up scope, given as Fixnum" do
            rails.declare_variable("my_variable", slot: 1, scope: 1)

            variable.scope.should be 1
          end

          it "complains about unknown scope" do
            expect do
              rails.declare_variable("my_variable", slot: 1, scope: //)
            end.to raise_exception(Configuration::VariableException)
          end
        end

        it "complains about an invalid slot"

        it "complains about a taken slot" do
          rails.declare_variable("my_variable", slot: 1)
          expect do
            rails.declare_variable("my_other_variable", slot: 1)
          end.to raise_exception Configuration::VariableException
        end

        it "complains about a taken name" do
          rails.declare_variable("my_variable", slot: 1)
          expect do
            rails.declare_variable("my_variable", slot: 2)
          end.to raise_exception Configuration::VariableException
        end
      end

      describe ".additional_trackers=" do
        it "complains about bad tracker names" do
          pending "could not find out about that in the docs"
          # probably, leading underscore is bad
        end

        it "makes tracker configs available" do
          rails.additional_trackers = [:foo, :bar]

          rails.tracker(:foo).should_not be rails.tracker(:bar)
        end

        it "tolerates symbols as well as strings" do
          rails.additional_trackers = [:foo, "bar"]

          rails.tracker(:foo).should_not be rails.tracker(:bar)
        end

        it "complains about name collision" do
          expect { rails.additional_trackers = ["foo", "foo"] }.to raise_exception
        end

        it "complains about name collision even if symbol and string is used" do
          expect { rails.additional_trackers = [:foo, "foo"] }.to raise_exception
        end
      end

      def find_tracker_config_by_name(name)
        name = name.to_s unless name.nil?
        result = subject.tracker_config(name)
        result.should_not be_nil
        result
      end

      describe ".tracker" do
        it "complains about a non-existent tracker name" do
          expect{ rails.tracker(:nonexistent) }.to raise_exception
        end

        it "returns something for a valid tracker name" do
          rails.additional_trackers = [:foo]

          rails.tracker(:foo).should_not be_nil
        end

        it "tolerates symbols as well as strings" do
          rails.additional_trackers = [:foo]

          rails.tracker(:foo).should be rails.tracker("foo")
        end

        it "delegates tracker setting setters to tracker configs" do
          rails.additional_trackers = [:foo]

          rails_tracker = rails.tracker(:foo)
          rails_tracker.web_property_id = "web property id"
          rails_tracker.track_pageview = :production

          tracker_config = find_tracker_config_by_name(:foo)
          tracker_config.web_property_id.should be == "web property id"
          tracker_config.track_pageview.should be :production
        end
      end

      it "delegates tracker setting setters to default tracker rails config object" do
        rails.web_property_id = "bla"

        default_tracker_config = find_tracker_config_by_name(nil)

        default_tracker_config.web_property_id.should be == "bla"
      end
    end

    describe "tracker_config" do
      it "returns nil when no tracker config by given name" do
        subject.tracker_config('bogus').should be_nil
      end

      it "returns a different object per tracker name" do
        rails.additional_trackers = [:foo, :bar]

        subject.tracker_config('foo').should_not be subject.tracker_config('bar')
      end

      it "only accepts tracker names as strings" do
        rails.additional_trackers = [:foo, :bar]

        subject.tracker_config(:foo).should be_nil
      end
    end

    describe "tracker_names" do
      it "initially is [nil]" do
        subject.tracker_names.should be == [nil]
      end

      context "after gaq.additional_trackers = [:foo, :bar]" do
        before do
          rails.additional_trackers = [:foo, :bar]
        end

        it "contains nil, 'foo' and 'bar'" do
          subject.tracker_names.should have(3).tracker_names
          subject.tracker_names.should include(nil)
          subject.tracker_names.should include('foo')
          subject.tracker_names.should include('bar')
        end
      end
    end

    describe "#render_ga_js" do
      it "equals :production by default" do
        subject.render_ga_js.should be :production
      end
    end

    describe "#render_ga_js?" do
      let(:environment) do
        ActiveSupport::StringInquirer.new(example.metadata[:env].to_s)
      end

      def result
        subject.render_ga_js?(environment)
      end


      describe "this StringInquirer setup" do
        it "works as expected", env: :development do
          environment.should be_development
          environment.should_not be_production
        end
      end

      context "without using rails_config.render_ga_js=" do
        it "returns true in production", env: :production do
          result.should be == true
        end

        it "returns false in development", env: :development do
          result.should be == false
        end

        it "returns false in test", env: :test do
          result.should be == false
        end
      end

      context "with rails_config.render_ga_js = true or false" do
        it "reports those values " do
          rails.render_ga_js = true
          result.should be == true

          rails.render_ga_js = false
          result.should be == false
        end
      end

      context "with rails_config.render_ga_ja = some symbol" do
        it "compares with given environment", env: :production do
          rails.render_ga_js = :production
          result.should be == true

          rails.render_ga_js = :development
          result.should be == false
        end
      end

      context "with rails_config.render_ga_ja = Array of symbols" do
        it "compares with given environment", env: :production do
          rails.render_ga_js = [:production, :test]
          result.should be == true

          rails.render_ga_js = [:development, :test]
          result.should be == false
        end
      end

      context "with rails_config.render_ga_ja = callable object (for interpret_config)" do
        it "passes it through" do
          lmbda = ->{}
          rails.render_ga_js = lmbda
          result.should be lmbda
        end
      end
    end
  end
end

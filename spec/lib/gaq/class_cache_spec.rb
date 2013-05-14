require 'gaq/class_cache'

module Gaq
  describe ClassCache do
    let(:assertion_double) { double }

    shared_context silence_double: true do
      before do
        assertion_double.as_null_object
      end
    end

    before do
      subject.building(:foo, String) do |cls|
        assertion_double.build(:foo)
        cls.class_eval do
          def foo
            "foo"
          end
        end
      end

      subject.building(:bar, Hash) do |cls|
        assertion_double.build(:bar)
        subject[:foo]
        cls.class_eval do
          def bar
            "bar"
          end
        end
      end
    end

    context silence_double: true do
      it "builds a class as instructed" do
        built = subject[:foo]
        built.should be < String
        built.new.foo.should be == "foo"
      end

      it "raises an exception on miss" do
        expect {
          subject[:baz]
        }.to raise_exception ClassCache::Miss
      end
    end

    it "only builds the class once" do
      assertion_double.should_receive(:build).with(:foo).once

      subject[:foo]
      subject[:foo]
    end

    it "implicitly supports dependencies" do
      assertion_double.should_receive(:build).with(:foo)

      assertion_double.should_receive(:build).with(:bar)
      subject[:bar]
    end
  end
end

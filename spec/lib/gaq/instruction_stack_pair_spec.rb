require 'gaq/instruction_stack_pair'

# TODO this could really need some more thoughts. It isn't very human-readable...

module Gaq
  describe InstructionStackPair do
    let(:early) { [] }
    let(:regular) { [] }

    context "constructed with 'early' and 'regular' arrays" do
      subject { described_class.new early, regular }

      describe "exposure of initialization args" do
        its(:to_a) { should be_equal(regular) }
        its(:early) { should be_equal(early) }
      end

      describe :push do
        it "pushes onto 'regular'" do
          first_obj = 'foo'
          subject.push first_obj
          subject.push 17
          subject.to_a.should have(2).items
          subject.to_a.first.should be_equal(first_obj)
          subject.to_a.last.should be_equal(17)
        end
      end
    end

    let(:pair_and_promise) do
      described_class.pair_and_next_request_promise(flash)
    end

    let(:pair) { pair_and_promise.first }
    let(:promise) { pair_and_promise.last }

    describe :pair_and_next_request_promise do
      before(:each) { pair } #trigger everything

      context "with empty flash" do
        let(:flash) { {} }

        it "did not alter flash" do
          flash.should be_empty
        end

        describe "pair result" do
          it "is an instance with empty 'early' and 'regular' part" do
            pair.should be_an_instance_of(described_class)
            pair.to_a.should be_empty
            pair.early.should be_empty
          end

          it "does not alter flash when pushing on either array" do
            pair.push 0
            pair.early.push 1
            flash.should be_empty
          end
        end

        describe "promise result" do
          it "is callable" do
            promise.should respond_to(:call)
          end

          describe "result when calling" do
            let(:promise_call_result) { promise.call }

            it "is an instance" do |variable|
              promise_call_result.should be_an_instance_of(described_class)
            end
          end
        end
      end
    end

    describe "livecycle with flash 'serialization'" do
      before(:each) { pair } #trigger everything

      context "with empty flash, pushing some items" do
        let(:flash) { {} }

        before(:each) do
          pair.push 0
          pair.early.push 1
        end

        context "after resolving promise and pushing some items on it" do
          let!(:promised_pair) { promise.call }

          before(:each) do
            promised_pair.push 2
            promised_pair.early.push 3
          end

          describe "pair created from flash" do
            let(:late_pair_and_promise) { described_class.pair_and_next_request_promise(flash) }

            let(:late_pair) { late_pair_and_promise.first }
            # let(:late_promise) { late_pair_and_promise.last }

            it "has items pushed onto promised pair, for 'early' and 'regular' resp." do
              late_pair.to_a.should be_eql([2])
              late_pair.early.to_a.should be_eql([3])
            end
          end
        end
      end
    end
  end
end

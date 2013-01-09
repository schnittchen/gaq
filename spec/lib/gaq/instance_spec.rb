require 'gaq/instance'

module Gaq
  describe Instance do
    let(:flash) { {} }
    let(:controller) do
      double("controller").tap do |cont|
        cont.stub(:flash) { flash }
      end
    end

    let(:config) do
      OpenStruct.new
    end

    let(:variables) do
      []
    end

    before(:each) do
      Gaq.stub(:config) { config }
      Gaq::Variables.stub(:cleaned_up) { variables }
    end

    subject do
      Instance.finalize
      described_class.new(controller).tap do |sub|
        sub.singleton_class.send :public, :gaq_instructions
      end
    end

    def be_empty_gaq_instructions
      be_eql ["['_setAccount', '']"]
    end

    context "initially" do
      it 'renders properly' do
        flash.should be_empty

        subject.gaq_instructions.should be_empty_gaq_instructions
      end
    end

    context "with track_event" do
      before(:each) do
        subject.track_event 'category', 'action', 'label'
      end

      it 'renders properly' do
        flash.should be_empty

        subject.gaq_instructions.should \
          be_eql(["['_setAccount', '']", "['_trackEvent', 'category', 'action', 'label']"])
      end
    end

    context "with next_request.track_event" do
      before(:each) do
        subject.next_request.track_event 'category', 'action', 'label'
      end

      it 'renders properly' do
        flash.should be_eql({:analytics_instructions=>[[], ["['_trackEvent', 'category', 'action', 'label']"]]})

        subject.gaq_instructions.should be_empty_gaq_instructions
      end
    end

    context "with a variable declared" do
      before(:each) do
        variables << { name: :var, scope: 3, slot: 0 }
      end

      context "...but not assigned" do
        it 'renders properly' do
          flash.should be_empty

          subject.gaq_instructions.should be_empty_gaq_instructions
        end
      end

      context "after assigning to variable" do
        before(:each) do
          subject.var = 'blah'
        end

        it "renders properly" do
          flash.should be_empty

          subject.gaq_instructions.should \
            be_eql(["['_setAccount', '']", "['_setCustomVar', '0', 'var', 'blah', '3']"])
        end

        context "with track_event" do
          before(:each) do
            subject.track_event 'category', 'action', 'label'
          end

          it 'renders properly' do
            flash.should be_empty

            subject.gaq_instructions.should \
              be_eql(["['_setAccount', '']", "['_setCustomVar', '0', 'var', 'blah', '3']", "['_trackEvent', 'category', 'action', 'label']"])
          end
        end

        context "with next_request.track_event" do
          before(:each) do
            subject.next_request.track_event 'category', 'action', 'label'
          end

          it 'renders properly' do
            flash.should be_eql({:analytics_instructions=>[[], ["['_trackEvent', 'category', 'action', 'label']"]]})

            subject.gaq_instructions.should \
              be_eql(["['_setAccount', '']", "['_setCustomVar', '0', 'var', 'blah', '3']"])
          end
        end
      end
    end
  end
end

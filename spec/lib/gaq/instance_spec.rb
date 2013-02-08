require 'gaq/instance'

module Gaq
  describe Instance do
    let(:flash) { {} }

    let(:pair_and_promise) do
      InstructionStackPair.pair_and_next_request_promise(flash)
    end

    let(:instruction_stack_pair) do
      pair_and_promise.first
    end

    let(:config) do
      OpenStruct.new.tap do |cfg|
        Tracker.default_tracker_config.web_property_id = 'UA-XXTESTYY-1'
        # cfg.web_property_id = 'UA-XXTESTYY-1'
      end
    end

    let(:variables) do
      []
    end

    before(:each) do
      Gaq.stub(:config) { config }
      Gaq::Variables.stub(:cleaned_up) { variables }
    end

    let(:next_request_pair_promise) do
      pair_and_promise.last
    end

    subject do
      Tracker.reset_methods_module
      Instance.finalize

      config_proxy = Instance::ConfigProxy.new(config, nil) # controller not needed here
      target_origin = TargetOrigin.new(instruction_stack_pair, next_request_pair_promise)

      described_class.new(target_origin, config_proxy).tap do |sub|
        sub.singleton_class.send :public, :gaq_instructions
      end
    end

    def rendered
      context = Class.new do

        # stolen from actionview
        def j(javascript)
          js_escape_map = { '\\' => '\\\\', '</' => '<\/', "\r\n" => '\n', "\n" => '\n', "\r" => '\n', '"' => '\\"', "'" => "\\'" }
          if javascript
            result = javascript.gsub(/(\\|<\/|\r\n|\342\200\250|[\n\r"'])/u) {|match| js_escape_map[match] }
            # javascript.html_safe? ? result.html_safe : result
            result
          else
            ''
          end
        end

        def javascript_tag(content)
          content_tag(:script, javascript_cdata_section(content)) #html_options.merge(:type => Mime::JS))
        end

        private

        def h(content)
          content #is already safe
          # content.encode(content.encoding, :xml => :attr)[1...-1]
        end

        def content_tag_string(name, content)
          tag_options = ' type="text/javascript"'
          "<#{name}#{tag_options}>#{h(content)}</#{name}>"
        end

        def content_tag(name, content)
          content_tag_string(name, content)
        end

        def javascript_cdata_section(content)
          "\n//#{cdata_section("\n#{content}\n//")}\n"
        end

        def cdata_section(content)
          "<![CDATA[#{content}]]>"
        end
      end.new

      subject.render(context)
    end

    def be_empty_gaq_instructions
      be == [["_setAccount", 'UA-XXTESTYY-1']]
    end

    context "initially" do
      it 'renders properly' do
        flash.should be_empty

        subject.gaq_instructions.should be_empty_gaq_instructions

        rendered.should be == %{<script type=\"text/javascript\">\n//<![CDATA[\nvar _gaq = _gaq || [];\n_gaq.push(['_setAccount', 'UA-XXTESTYY-1']);\n//]]>\n</script>}
      end
    end

    context "with track_event" do
      before(:each) do
        subject.track_event 'category', 'action', 'label'
      end

      it 'renders properly' do
        flash.should be_empty

        subject.gaq_instructions.should \
          be ==([["_setAccount", 'UA-XXTESTYY-1'], ["_trackEvent", "category", "action", "label"]])

        rendered.should be == %{<script type=\"text/javascript\">\n//<![CDATA[\nvar _gaq = _gaq || [];\n_gaq.push(['_setAccount', 'UA-XXTESTYY-1'],\n  [\"_trackEvent\", \"category\", \"action\", \"label\"]);\n//]]>\n</script>}
      end
    end

    context "with next_request.track_event" do
      before(:each) do
        subject.next_request.track_event 'category', 'action', 'label'
      end

      it 'renders properly' do
        flash.should be ==({:analytics_instructions=>[[], [["_trackEvent", "category", "action", "label"]]]})

        subject.gaq_instructions.should be_empty_gaq_instructions

        rendered.should be == %{<script type=\"text/javascript\">\n//<![CDATA[\nvar _gaq = _gaq || [];\n_gaq.push(['_setAccount', 'UA-XXTESTYY-1']);\n//]]>\n</script>}
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

          rendered.should be == %{<script type=\"text/javascript\">\n//<![CDATA[\nvar _gaq = _gaq || [];\n_gaq.push(['_setAccount', 'UA-XXTESTYY-1']);\n//]]>\n</script>}
        end
      end

      context "after assigning to variable" do
        before(:each) do
          subject.var = 'blah'
        end

        it "renders properly" do
          flash.should be_empty

          subject.gaq_instructions.should \
            be ==([["_setAccount", 'UA-XXTESTYY-1'], ["_setCustomVar", 0, :var, "blah", 3]])

          rendered.should be == %{<script type=\"text/javascript\">\n//<![CDATA[\nvar _gaq = _gaq || [];\n_gaq.push(['_setAccount', 'UA-XXTESTYY-1'],\n  ['_setCustomVar', '0', 'var', 'blah', '3']);\n//]]>\n</script>}
        end

        context "with track_event" do
          before(:each) do
            subject.track_event 'category', 'action', 'label'
          end

          it 'renders properly' do
            flash.should be_empty

            subject.gaq_instructions.should \
              be ==([["_setAccount", 'UA-XXTESTYY-1'], ["_setCustomVar", 0, :var, "blah", 3], ["_trackEvent", "category", "action", "label"]])

            rendered.should be == %{<script type=\"text/javascript\">\n//<![CDATA[\nvar _gaq = _gaq || [];\n_gaq.push(['_setAccount', 'UA-XXTESTYY-1'],\n  ['_setCustomVar', '0', 'var', 'blah', '3'],\n  [\"_trackEvent\", \"category\", \"action\", \"label\"]);\n//]]>\n</script>}
          end
        end

        context "with next_request.track_event" do
          before(:each) do
            subject.next_request.track_event 'category', 'action', 'label'
          end

          it 'renders properly' do
            flash.should be ==({:analytics_instructions=>[[], [["_trackEvent", "category", "action", "label"]]]})

            subject.gaq_instructions.should \
              be ==([["_setAccount", 'UA-XXTESTYY-1'], ["_setCustomVar", 0, :var, "blah", 3]])

            rendered.should be == %{<script type=\"text/javascript\">\n//<![CDATA[\nvar _gaq = _gaq || [];\n_gaq.push(['_setAccount', 'UA-XXTESTYY-1'],\n  ['_setCustomVar', '0', 'var', 'blah', '3']);\n//]]>\n</script>}
          end
        end

        context "with both next_request.track_event and setting variable on next_request result" do
          before(:each) do
            subject.next_request.track_event 'category', 'action', 'label'
            subject.next_request.var = 'blah'
          end

          it 'has data on the flash we are interested in' do
            expected_flash = {:analytics_instructions=>[[["_setCustomVar", 0, :var, "blah", 3]], [["_trackEvent", "category", "action", "label"]]]}
            flash.should be ==(expected_flash)

            rendered.should == %{<script type=\"text/javascript\">\n//<![CDATA[\nvar _gaq = _gaq || [];\n_gaq.push(['_setAccount', 'UA-XXTESTYY-1'],\n  ['_setCustomVar', '0', 'var', 'blah', '3']);\n//]]>\n</script>}
          end
        end
      end
    end

    context "with a non-empty flash" do
      let(:flash_from_last_request) do
        {:analytics_instructions=>[[["_setCustomVar", 0, :var, "blah", 3]], [["_trackEvent", "last_cat", "last_action", "last_label"]]]}
      end

      let(:flash) { flash_from_last_request }

      def be_gaq_instructions_from_previous_request
        be == [["_setAccount", 'UA-XXTESTYY-1'], ["_setCustomVar", 0, :var, "blah", 3], ["_trackEvent", "last_cat", "last_action", "last_label"]]
      end

      it 'renders properly' do
        subject.gaq_instructions.should be_gaq_instructions_from_previous_request
        flash.should be_equal(flash_from_last_request)

        rendered.should be == %{<script type=\"text/javascript\">\n//<![CDATA[\nvar _gaq = _gaq || [];\n_gaq.push(['_setAccount', 'UA-XXTESTYY-1'],\n  ['_setCustomVar', '0', 'var', 'blah', '3'],\n  ['_trackEvent', 'last_cat', 'last_action', 'last_label']);\n//]]>\n</script>}
      end

      context "with track_event" do
        before(:each) do
          subject.track_event 'category', 'action', 'label'
        end

        it 'renders properly' do
          flash.should be_equal(flash_from_last_request)

          subject.gaq_instructions.should \
            be ==([["_setAccount", 'UA-XXTESTYY-1'], ["_setCustomVar", 0, :var, "blah", 3], ["_trackEvent", "last_cat", "last_action", "last_label"], ["_trackEvent", "category", "action", "label"]])

          rendered.should be == %{<script type=\"text/javascript\">\n//<![CDATA[\nvar _gaq = _gaq || [];\n_gaq.push(['_setAccount', 'UA-XXTESTYY-1'],\n  ['_setCustomVar', '0', 'var', 'blah', '3'],\n  ['_trackEvent', 'last_cat', 'last_action', 'last_label'],\n  [\"_trackEvent\", \"category\", \"action\", \"label\"]);\n//]]>\n</script>}
        end
      end

      context "with next_request.track_event" do
        before(:each) do
          subject.next_request.track_event 'category', 'action', 'label'
        end

        it 'renders properly' do
          flash.should be ==({:analytics_instructions=>[[], [["_trackEvent", "category", "action", "label"]]]})

          subject.gaq_instructions.should be_gaq_instructions_from_previous_request

          rendered.should be == %{<script type=\"text/javascript\">\n//<![CDATA[\nvar _gaq = _gaq || [];\n_gaq.push(['_setAccount', 'UA-XXTESTYY-1'],\n  ['_setCustomVar', '0', 'var', 'blah', '3'],\n  ['_trackEvent', 'last_cat', 'last_action', 'last_label']);\n//]]>\n</script>}
        end
      end

      context "with a variable declared" do
        before(:each) do
          variables << { name: :var, scope: 3, slot: 0 }
        end

        context "...but not assigned" do
          it 'renders properly' do
            flash.should be_equal(flash_from_last_request)

            subject.gaq_instructions.should be_gaq_instructions_from_previous_request

            rendered.should be == %{<script type=\"text/javascript\">\n//<![CDATA[\nvar _gaq = _gaq || [];\n_gaq.push(['_setAccount', 'UA-XXTESTYY-1'],\n  ['_setCustomVar', '0', 'var', 'blah', '3'],\n  ['_trackEvent', 'last_cat', 'last_action', 'last_label']);\n//]]>\n</script>}
          end
        end

        context "after assigning to variable" do
          before(:each) do
            subject.var = 'blubb'
          end

          it "renders properly" do
            flash.should be_equal(flash_from_last_request)

            subject.gaq_instructions.should \
              be ==([["_setAccount", 'UA-XXTESTYY-1'], ["_setCustomVar", 0, :var, "blah", 3], ["_setCustomVar", 0, :var, "blubb", 3], ["_trackEvent", "last_cat", "last_action", "last_label"]])

            rendered.should be == %{<script type=\"text/javascript\">\n//<![CDATA[\nvar _gaq = _gaq || [];\n_gaq.push(['_setAccount', 'UA-XXTESTYY-1'],\n  ['_setCustomVar', '0', 'var', 'blah', '3'],\n  ['_setCustomVar', '0', 'var', 'blubb', '3'],\n  ['_trackEvent', 'last_cat', 'last_action', 'last_label']);\n//]]>\n</script>}
          end

          context "with track_event" do
            before(:each) do
              subject.track_event 'category', 'action', 'label'
            end

            it 'renders properly' do
              # flash.should be_empty
              # FIXME documenting behaviour here that is probably wrong (double check if needed)
              flash.should be ==({:analytics_instructions=>[[["_setCustomVar", 0, :var, "blah", 3], ["_setCustomVar", 0, :var, "blubb", 3]], [["_trackEvent", "last_cat", "last_action", "last_label"], ["_trackEvent", "category", "action", "label"]]]})

              subject.gaq_instructions.should \
                be ==([["_setAccount", 'UA-XXTESTYY-1'], ["_setCustomVar", 0, :var, "blah", 3], ["_setCustomVar", 0, :var, "blubb", 3], ["_trackEvent", "last_cat", "last_action", "last_label"], ["_trackEvent", "category", "action", "label"]])

              rendered.should be == %{<script type=\"text/javascript\">\n//<![CDATA[\nvar _gaq = _gaq || [];\n_gaq.push(['_setAccount', 'UA-XXTESTYY-1'],\n  ['_setCustomVar', '0', 'var', 'blah', '3'],\n  ['_setCustomVar', '0', 'var', 'blubb', '3'],\n  ['_trackEvent', 'last_cat', 'last_action', 'last_label'],\n  [\"_trackEvent\", \"category\", \"action\", \"label\"]);\n//]]>\n</script>}
            end
          end

          context "with next_request.track_event" do
            before(:each) do
              subject.next_request.track_event 'category', 'action', 'label'
            end

            it 'renders properly' do
              flash.should be ==({:analytics_instructions=>[[], [["_trackEvent", "category", "action", "label"]]]})

              subject.gaq_instructions.should \
                be ==([["_setAccount", 'UA-XXTESTYY-1'], ["_setCustomVar", 0, :var, "blah", 3], ["_setCustomVar", 0, :var, "blubb", 3], ["_trackEvent", "last_cat", "last_action", "last_label"]])

              rendered.should be == %{<script type=\"text/javascript\">\n//<![CDATA[\nvar _gaq = _gaq || [];\n_gaq.push(['_setAccount', 'UA-XXTESTYY-1'],\n  ['_setCustomVar', '0', 'var', 'blah', '3'],\n  ['_setCustomVar', '0', 'var', 'blubb', '3'],\n  ['_trackEvent', 'last_cat', 'last_action', 'last_label']);\n//]]>\n</script>}
            end
          end
        end
      end

      context "with a custom tracker" do
        before(:each) do
          subject[:foo].track_event 'category', 'action', 'label'
        end

        it 'renders properly' do
          flash.should be_equal(flash_from_last_request)

          subject.gaq_instructions.should \
            be == [
              ["_setAccount", 'UA-XXTESTYY-1'],
              ["_setCustomVar", 0, :var, "blah", 3],
              ["_trackEvent", "last_cat", "last_action", "last_label"],
              ["foo._trackEvent", "category", "action", "label"]
            ]

          rendered.should be == %{<script type=\"text/javascript\">\n//<![CDATA[\nvar _gaq = _gaq || [];\n_gaq.push(['_setAccount', 'UA-XXTESTYY-1'],\n  ['_setCustomVar', '0', 'var', 'blah', '3'],\n  ['_trackEvent', 'last_cat', 'last_action', 'last_label'],\n  [\"foo._trackEvent\", \"category\", \"action\", \"label\"]);\n//]]>\n</script>}
        end
      end
    end
  end
end

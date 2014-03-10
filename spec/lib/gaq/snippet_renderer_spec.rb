require 'gaq/snippet_renderer'

module Gaq
  describe SnippetRenderer do
    let(:rendering_context) do
      double("rendering context").tap do |context|
        # no assertion?? XXX
        context.stub(:javascript_tag) { |content| content }
      end
    end

    let(:config) do
      double "config"
    end

    let(:rails_env) do
      double "rails env"
    end

    subject do
      described_class.new(rendering_context, config, rails_env)
    end

    describe "#render" do
      def pushed_arrays(rendered)
        rendered = rendered.lines.drop_while { |line| !/^\s*_gaq.push/.match(line) }
        rendered = rendered.take_while { |line| !line.empty? }

        rendered = rendered.join('')[/\A\_gaq.push\((.*)\);\Z/m, 1]
        rendered = rendered.split(/,\n\s*/)
        rendered.map { |string| JSON.parse(string) }
      end

      it "renders commands segments" do
        config.stub(:support_display_ads) { false }
        config.stub(:render_ga_js?) { false }

        commands_as_segments = [
          ["foo", "bar"],
          ["baz", true, 3]
        ]
        rendered = subject.render(commands_as_segments)

        pushed_arrays(rendered).should be == commands_as_segments
      end

      describe "snippet rendering" do
        it "renders the snippet when config.render_ga_js? returns true" do
          config.stub(:render_ga_js?) { true }
          config.stub(:support_display_ads) { true }
          subject.render([]).should include('stats.g.doubleclick.net')
        end

        it "renders the snippet when config.render_ga_js? returns true" do
          config.stub(:render_ga_js?) { true }
          config.stub(:support_display_ads) { false }
          subject.render([]).should include('google-analytics.com')
        end

        it "does not render the snippet when config.render_ga_js? returns false" do
          config.stub(:render_ga_js?) { false }
          config.stub(:support_display_ads) { false }
          subject.render([]).should_not include('google-analytics.com')
        end
      end
    end

  end
end

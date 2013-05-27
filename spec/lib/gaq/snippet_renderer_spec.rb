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
      def pushed_jsons(rendered)
        rendered = rendered.lines.drop_while { |line| !/^\s*_gaq.push/.match(line) }
        rendered = rendered.take_while { |line| !line.empty? }

        rendered = /\A\_gaq.push\((.*)\);\Z/m.match(rendered.join(''))[1]
        rendered = rendered.split(/,\n\s*/)
        rendered
      end

      it "foo" do
        config.stub(:render_ga_js?) { false }

        commands_as_segments = [
          ["foo", "bar"],
          ["baz", true, 3]
        ]
        result = subject.render(commands_as_segments)

        pushed_jsons(result).should be == [
          '["foo", "bar"]',
          '["baz", true, 3]'
        ]
      end

      describe "snippet rendering" do
        it "renders the snippet when config.render_ga_js? returns true" do
          config.stub(:render_ga_js?) { true }
          subject.render([]).should include('google-analytics.com')
        end

        it "does not render the snippet when config.render_ga_js? returns false" do
          config.stub(:render_ga_js?) { false }
          subject.render([]).should_not include('google-analytics.com')
        end
      end
    end

  end
end

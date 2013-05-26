require 'nokogiri'

module Helpers
  def gaq_cdata
    html = Nokogiri::HTML.parse(page.body)

    html.css('script[type="text/javascript"]').find do |script|
      cdata = script.children.find(&:cdata?) \
        and cdata.text.include?('_gaq') \
        and break(cdata)
    end
  end

  def gaq_cdata_content
    /<!\[CDATA\[(.*)\]\]>/m.match(gaq_cdata)[1]
  end

  def gaq_split_at_snippet_beginning
    text_lines_without_comments = gaq_cdata_content.split("\n").map do |line|
      if me = %r{^(.*?)//}.match(line)
        line = me[1]
      end

      if me = %r{^\s*(.*)}.match(line)
        line = me[1]
      end

      line
    end.reject(&:blank?)

    text_lines_without_comments.join("\n").split(%r{(?=\(function\(\))})
  end

  def snippet_and_beyond
    gaq_split_at_snippet_beginning[1..-1]
  end

  def gaq_js_instructions
    gaq_split_at_snippet_beginning.first.split(%r{(?<=;)\n}m)
  end

  def gaq_pushed_instructions
    # we cannot use JSON.parse here because I was so stupid to use "'" as string delimiter
    lines = %r{\A_gaq.push\((.*)\);\Z}m.match(gaq_js_instructions.second)[1]
    lines.split(",\n").map do |instruction_line|
      instruction_line.should start_with('[')
      instruction_line.should end_with(']')
      instruction_line[1..-2].split(/,\s*/).map do |segment|
        if segment[0] == "'"
          segment.should start_with("'")
          segment.should end_with("'")
        else
          segment.should start_with('"')
          segment.should end_with('"')
        end
        segment[1..-2]
      end
    end
  end

  def track_event_from_before_filter(action)
    be_instruction('_trackEvent').with_args("controller", "action", action)
  end
end

RSpec.configure{ |c| c.include Helpers }

RSpec::Matchers.define :be_instruction do |instruction|
  match do |actual|
    (actual.first == instruction) &&
      if defined?(@instruction_args)
        (actual.drop(1) == @instruction_args)
      else
        true
      end
  end

  chain :with_args do |*args|
    @instruction_args = args
  end

  chain :without_args do
    @instruction_args = []
  end

  failure_message_for_should do |actual|
    message = "expected that #{actual} would be instruction #{instruction.inspect}"
    if @instruction_args
      if @instruction_args.empty?
        message << "without args"
      else
        message << " with args #{@instruction_args}"
      end
    end
    message
  end
end
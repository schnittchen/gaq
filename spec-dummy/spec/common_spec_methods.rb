require 'nokogiri'

module Helpers
  def gaq_cdata
    return @gaq_cdata if @gaq_cdata
    html = Nokogiri::HTML.parse(page.body)

    @gaq_cdata = html.css('script[type="text/javascript"]').find do |script|
      cdata = script.children.find(&:cdata?) \
        and cdata.text.include?('_gaq') \
        and break(cdata)
    end
  end

  def gaq_cdata_content
    /<!\[CDATA\[(.*)\]\]>/m.match(gaq_cdata)[1]
  end

  def gaq_js_lines
    gaq_cdata_content.split("\n").reject(&:empty?).reject do |line|
      %r{\A\s*//}.match(line)
    end
  end
end

RSpec.configure{ |c| c.include Helpers }

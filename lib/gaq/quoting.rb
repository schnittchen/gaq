require 'action_view'

module Gaq
  module Quoting
    include ActionView::Helpers::JavaScriptHelper

    private

    def quoted_gaq_item(*args)
      arguments = args.map { |arg| "'#{j arg.to_s}'" }.join ', '
      return "[#{arguments}]"
    end
  end
end

require 'gaq/version'

require 'gaq/instance'
require 'gaq/railtie'

module Gaq
  def self.config
    Railtie.config.gaq
  end
end

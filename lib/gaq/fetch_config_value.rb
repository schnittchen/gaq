module Gaq
  module FetchConfigValue
    def fetch_config_value(key, config = config)
      result = config[key]
      result = result.call(controller_facade) if result.respond_to?(:call)
      result
    end
  end
end

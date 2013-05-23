module Gaq
  module InterpretsConfig
    private

    def interpret_config(value, controller_facade)
      if value.respond_to?(:call)
        controller_facade.evaluate_config_lambda(value)
      else
        value
      end
    end
  end
end

module Gaq
  class ControllerFacade
    def initialize(controller)
      @controller = controller
    end

    def flash
      @controller.flash
    end

    def evaluate_config_lambda(lmbda)
      lmbda.call(@controller)
    end
  end
end

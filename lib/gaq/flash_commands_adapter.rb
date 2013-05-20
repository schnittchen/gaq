module Gaq
  class FlashCommandsAdapter
    def initialize(language, controller_facade)
      @language, @controller_facade = language, controller_facade
      @commands = []
    end

    def <<(command)
      @commands << command
      set_flash
    end

    FLASH_KEY = :gaqgem

    def commands_from_flash
      flash_items = @controller_facade.flash[FLASH_KEY] || []
      @language.commands_from_flash_items(flash_items)
    end

    private

    def set_flash
      @controller_facade.flash[FLASH_KEY] = @language.commands_to_flash_items(@commands)
    end
  end
end

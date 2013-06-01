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

    # bump this every time picking up old data from a flash
    # (which is part of the session cookie)
    # might break things
    FLASH_FORMAT_VERSION = 1

    def commands_from_flash
      flash_data = @controller_facade.flash[FLASH_KEY]
      flash_data = [FLASH_FORMAT_VERSION] unless flash_data_current?(flash_data)

      flash_items = flash_data.drop(1)
      @language.commands_from_flash_items(flash_items)
    end

    private

    def set_flash
      @controller_facade.flash[FLASH_KEY] = [
        FLASH_FORMAT_VERSION,
        *@language.commands_to_flash_items(@commands)
      ]
    end

    def flash_data_current?(flash_data)
      # flash_data may be nil (nothing in flash yet) or an array.
      return false unless flash_data

      # flash data is legacy unless first array item is a Fixnum
      return false unless flash_data.first.is_a?(Fixnum)

      # Mismatching versions are not current.
      flash_data.first == FLASH_FORMAT_VERSION
    end
  end
end

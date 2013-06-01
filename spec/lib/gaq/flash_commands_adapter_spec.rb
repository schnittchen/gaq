require 'gaq/flash_commands_adapter'

module Gaq
  describe FlashCommandsAdapter do
    let(:flash) { {} }

    let(:language) do
      result = double "language"
      if example.metadata[:null_conversion]
        result.stub(:commands_to_flash_items) { |commands| commands }
        result.stub(:commands_from_flash_items) { |commands| commands }
      end
      result
    end
    let(:controller_facade) do
      result = double "controller facade"
      result.stub(:flash) { flash }
      result
    end

    subject do
      described_class.new(language, controller_facade)
    end

    def commands_as_seen_in_flash
      flash[described_class::FLASH_KEY].drop(1)
    end

    def version_as_seen_in_flash
      flash[described_class::FLASH_KEY].first
    end

    def version_as_coded
      described_class::FLASH_FORMAT_VERSION
    end

    describe "#<<" do
      it "saves to flash with pushed command", null_conversion: true do
        subject << 5
        commands_as_seen_in_flash.should be == [5]
      end

      it "saves to flash with pushed commands", null_conversion: true do
        subject << 5
        subject << 17
        commands_as_seen_in_flash.should be == [5, 17]
      end

      it "converts items using language.commands_to_flash_items" do
        language.should_receive(:commands_to_flash_items).with([5]).and_return([:bogus])
        language.should_receive(:commands_to_flash_items).with([5, 17]).and_return([:result_array])

        subject << 5
        subject << 17

        commands_as_seen_in_flash.should be == [:result_array]
      end

      it "saves to flash including current format version", null_conversion: true do
        subject << 5

        version_as_seen_in_flash.should be == version_as_coded
      end
    end

    describe "#commands_from_flash" do
      context "with empty flash" do
        it "returns something empty", null_conversion: true do
          subject.commands_from_flash.should be_empty
        end
      end

      context "with current data in flash" do
        before do
          flash[described_class::FLASH_KEY] = [
            described_class::FLASH_FORMAT_VERSION,
            2,
            3
          ]
        end

        it "passes flash items through language.commands_from_flash_items and returns result" do
          language.should_receive(:commands_from_flash_items)
            .with([2, 3]).and_return([:conversion, :result])
          subject.commands_from_flash.should be == [:conversion, :result]
        end
      end

      context "with stale data in flash" do
        before do
          flash[described_class::FLASH_KEY] = [
            described_class::FLASH_FORMAT_VERSION - 1,
            2,
            3
          ]
        end

        it "returns something empty", null_conversion: true do
          subject.commands_from_flash.should be_empty
        end
      end

      context "with ancient data in flash" do
        before do
          flash[described_class::FLASH_KEY] = [
            ["_trackEvent", "foo", "bar", "baz"]
          ]
        end

        it "returns something empty", null_conversion: true do
          subject.commands_from_flash.should be_empty
        end
      end
    end
  end
end

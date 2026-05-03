# frozen_string_literal: true

module Run
  class AppConfigValidator
    def self.validate!(app_config, mode)
      new(app_config, mode).validate!
    end

    def initialize(app_config, mode)
      @app_config = app_config
      @mode = mode
    end

    def validate!
      validate_recorded_only_in_detailed!
    end

    private

    attr_reader :app_config, :mode

    def validate_recorded_only_in_detailed!
      return unless mode == "success_rate" && app_config["return_sequence_type"] == "recorded"

      raise "`return_sequence_type: recorded` is only valid with `mode: detailed`. " \
            "A recorded sequence is deterministic — running it 1000 times would " \
            "produce 1000 identical results."
    end
  end
end

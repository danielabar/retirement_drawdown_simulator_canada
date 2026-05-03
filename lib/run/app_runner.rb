# frozen_string_literal: true

module Run
  class AppRunner
    def initialize(config_file, mode_override = nil)
      @config_file = config_file
      @app_config = AppConfig.new(config_file)
      @mode = mode_override || @app_config["mode"] || "detailed"
    end

    def run
      puts "AppRunner initialized with config: #{config_file}, resolved mode: #{mode}"
      AppConfigValidator.validate!(app_config, mode)

      case mode
      when "detailed" then SimulationDetailed.new(app_config).run
      when "success_rate" then SuccessRateSimulation.new(app_config).run
      else puts "Invalid mode: #{mode}"
      end
    end

    private

    attr_reader :config_file, :app_config, :mode
  end
end

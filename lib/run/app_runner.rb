# frozen_string_literal: true

module Run
  class AppRunner
    def initialize(config_file, mode_override = nil)
      @app_config = AppConfig.new(config_file)
      @mode = mode_override || @app_config["mode"] || "detailed"
      puts "AppRunner initialized with config: #{config_file}, resolved mode: #{@mode}"
    end

    def run
      case mode
      when "detailed" then SimulationDetailed.new(app_config).run
      when "success_rate" then SuccessRateSimulation.new(app_config).run
      else puts "Invalid mode: #{mode}"
      end
    end

    private

    attr_reader :app_config, :mode
  end
end

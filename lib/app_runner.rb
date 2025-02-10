# frozen_string_literal: true

require "tty-progressbar"

class AppRunner
  def initialize(config_file, mode_override = nil)
    @app_config = AppConfig.new(config_file)
    @mode = mode_override || @app_config["mode"]
  end

  def run
    case mode
    when "detailed" then run_detailed_simulation
    when "success_rate" then run_success_rate_simulation
    else puts "Invalid mode: #{mode}"
    end
  end

  private

  attr_reader :app_config, :mode

  def run_detailed_simulation
    first_year_cash_flow_results = FirstYearCashFlow.new(app_config).calculate
    simulation_results = Simulator.new(app_config).run
    evaluator_results = SimulationEvaluator.new(simulation_results, app_config).evaluate

    formatter = SimulatorFormatter.new(simulation_results, first_year_cash_flow_results, evaluator_results)
    formatter.print_all
  end

  def run_success_rate_simulation
    total_runs = app_config["total_runs"] || 5000
    success_count = 0

    bar = TTY::ProgressBar.new("Simulating... [:bar] :percent",
                               total: total_runs,
                               bar_format: :smooth,
                               width: 40,
                               complete: "█",
                               incomplete: "░",
                               hide_cursor: true)

    total_runs.times do
      simulation_results = Simulator.new(app_config).run
      evaluator_results = SimulationEvaluator.new(simulation_results, app_config).evaluate

      success_count += 1 if evaluator_results[:success]
      bar.advance
    end

    success_rate = (success_count.to_f / total_runs) * 100
    puts "\nSimulation Success Rate: \e[32m#{success_rate.round(2)}%\e[0m ✅"
  end
end

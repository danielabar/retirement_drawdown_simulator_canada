# frozen_string_literal: true

require "tty-progressbar"

module Run
  class SuccessRateSimulation
    def initialize(app_config)
      @app_config = app_config
      @total_runs = app_config["total_runs"] || 500
      @withdrawal_rate = nil
    end

    def run
      success_count = 0
      progress_bar = create_progress_bar

      total_runs.times do |_i|
        success, withdrawal_rate = simulate_once

        # Store withdrawal_rate from the first run
        @withdrawal_rate ||= withdrawal_rate

        success_count += success
        progress_bar.advance
      end

      display_results(success_count)
    end

    private

    attr_reader :app_config, :total_runs, :withdrawal_rate

    def create_progress_bar
      TTY::ProgressBar.new("Simulating... [:bar] :percent",
                           total: total_runs,
                           bar_format: :smooth,
                           width: 40,
                           complete: "█",
                           incomplete: "░",
                           hide_cursor: true)
    end

    def simulate_once
      simulation_results = Simulation::Simulator.new(app_config).run
      evaluator_results = Simulation::SimulationEvaluator.new(simulation_results, app_config).evaluate

      [evaluator_results[:success] ? 1 : 0, evaluator_results[:withdrawal_rate]]
    end

    def display_results(success_count)
      success_rate = (success_count.to_f / total_runs) * 100

      puts "\nWithdrawal Rate: #{NumericFormatter.format_percentage(withdrawal_rate)}"
      puts "Simulation Success Rate: \e[32m#{success_rate.round(2)}%\e[0m ✅"
    end
  end
end

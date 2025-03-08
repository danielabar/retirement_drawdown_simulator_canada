# frozen_string_literal: true

module Run
  class SuccessRateSimulation
    def initialize(app_config)
      @app_config = app_config
      @total_runs = app_config["total_runs"] || 500
      @simulation_results = []
    end

    def run
      progress_bar = create_progress_bar

      total_runs.times do
        # Collect results from each run
        success, withdrawal_rate, final_balance = simulate_once
        @simulation_results << { success: success, withdrawal_rate: withdrawal_rate, final_balance: final_balance }
        progress_bar.advance
      end

      results = SuccessRateResults.new(simulation_results)
      Output::SuccessRatePrinter.new(results).print_summary
    end

    private

    attr_reader :app_config, :total_runs, :simulation_results

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
      evaluator_results = Simulation::SimulationEvaluator.new(simulation_results[:yearly_results], app_config).evaluate

      [
        evaluator_results[:success] ? true : false,
        evaluator_results[:withdrawal_rate],
        simulation_results[:yearly_results].last[:total_balance]
      ]
    end
  end
end

# frozen_string_literal: true

module Run
  class SuccessRateSimulation
    def initialize(app_config, failed_runs_writer: nil)
      @app_config = app_config
      @total_runs = app_config["total_runs"] || 500
      @simulation_results = []
      @failed_runs_writer = failed_runs_writer || FailedRuns::Writer.new(app_config)
    end

    def run
      @failed_runs_writer.prepare!
      progress_bar = create_progress_bar

      total_runs.times do
        # Collect results from each run
        success, withdrawal_rate, final_balance, annuity_skipped = simulate_once
        @simulation_results << { success: success, withdrawal_rate: withdrawal_rate, final_balance: final_balance,
                                 annuity_skipped: annuity_skipped }
        progress_bar.advance
      end

      @failed_runs_writer.flush!
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
      simulation_output = Simulation::Simulator.new(app_config).run
      evaluator_results = Simulation::SimulationEvaluator.new(simulation_output[:yearly_results], app_config).evaluate
      annuity_skipped = simulation_output[:yearly_results].any? { |r| r[:annuity_purchase_skipped] }
      @failed_runs_writer.offer(simulation_output, evaluator_results)

      [
        evaluator_results[:success] ? true : false,
        evaluator_results[:withdrawal_rate],
        simulation_output[:yearly_results].last[:total_balance],
        annuity_skipped
      ]
    end
  end
end

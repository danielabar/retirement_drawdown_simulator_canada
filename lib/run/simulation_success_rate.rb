# frozen_string_literal: true

# TODO: 35 - break up into classes and test (runners excluded from coverage)
# getting too much logic in the runner
# Think about a class to gather results, and another class to display them
module Run
  class SuccessRateSimulation
    def initialize(app_config)
      @app_config = app_config
      @total_runs = app_config["total_runs"] || 500
      @withdrawal_rate = nil
      @final_balances = []
    end

    def run
      success_count = 0
      progress_bar = create_progress_bar

      total_runs.times do |_i|
        success, withdrawal_rate, final_balance = simulate_once

        @withdrawal_rate ||= withdrawal_rate
        @final_balances << final_balance

        success_count += success
        progress_bar.advance
      end

      display_results(success_count)
    end

    private

    attr_reader :app_config, :total_runs, :withdrawal_rate, :final_balances

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

      [evaluator_results[:success] ? 1 : 0, evaluator_results[:withdrawal_rate],
       simulation_results[:yearly_results].last[:total_balance]]
    end

    def display_results(success_count)
      success_rate = (success_count.to_f / total_runs) * 100
      percentiles = calculate_percentiles

      puts "\nWithdrawal Rate: #{NumericFormatter.format_percentage(withdrawal_rate)}"
      puts "Simulation Success Rate: \e[32m#{success_rate.round(2)}%\e[0m"

      puts "\nDistribution of Final Balances:"
      puts "  10th percentile: #{NumericFormatter.format_currency(percentiles[10])}"
      puts "  25th percentile: #{NumericFormatter.format_currency(percentiles[25])}"
      puts "  50th percentile (median): #{NumericFormatter.format_currency(percentiles[50])}"
      puts "  75th percentile: #{NumericFormatter.format_currency(percentiles[75])}"
      puts "  90th percentile: #{NumericFormatter.format_currency(percentiles[90])}"
    end

    def calculate_percentiles
      sorted_balances = final_balances.sort
      {
        10 => sorted_balances.percentile(10),
        25 => sorted_balances.percentile(25),
        50 => sorted_balances.percentile(50),
        75 => sorted_balances.percentile(75),
        90 => sorted_balances.percentile(90)
      }
    end
  end
end

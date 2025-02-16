# frozen_string_literal: true

require "tty-progressbar"
require "time"

module Run
  class SuccessRateSimulation
    def initialize(app_config)
      @app_config = app_config
      @total_runs = app_config["total_runs"] || 5000
    end

    def run
      success_count = 0
      progress_bar = create_progress_bar

      # Record the start time
      start_time = Time.now

      total_runs.times do
        success_count += simulate_once
        progress_bar.advance
      end

      # Record the end time and calculate elapsed time
      end_time = Time.now
      elapsed_time = end_time - start_time

      display_success_rate(success_count)
      display_time_taken(elapsed_time)
    end

    private

    attr_reader :app_config, :total_runs

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
      evaluator_results[:success] ? 1 : 0
    end

    def display_success_rate(success_count)
      success_rate = (success_count.to_f / total_runs) * 100
      puts "\nSimulation Success Rate: \e[32m#{success_rate.round(2)}%\e[0m ✅"
    end

    def display_time_taken(elapsed_time)
      minutes = (elapsed_time / 60).to_i
      seconds = (elapsed_time % 60).to_i
      puts "Time taken: \e[34m#{minutes}m #{seconds}s\e[0m"
    end
  end
end

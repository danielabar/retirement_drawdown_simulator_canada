# frozen_string_literal: true

# TODO: A single app runner, and input/config to decide whether to run one simulation with output or this multi-run
# Also would be nice for total_runs to be configurable
require_relative "config/environment"
require "tty-progressbar"

app_config = AppConfig.new("inputs_fire.yml")

success_count = 0
total_runs = 5_000

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

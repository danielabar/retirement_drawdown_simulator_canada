# frozen_string_literal: true

require_relative "config/environment"

app_config = AppConfig.new("inputs.yml")

success_count = 0
total_runs = 10_000

total_runs.times do
  simulation_results = Simulator.new(app_config).run
  evaluator_results = SimulationEvaluator.new(simulation_results, app_config).evaluate

  success_count += 1 if evaluator_results[:success]
end

success_rate = (success_count.to_f / total_runs) * 100

puts "Simulation Success Rate: #{success_rate.round(2)}%"

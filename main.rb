# frozen_string_literal: true

require_relative "config/environment"

app_config = AppConfig.new("inputs.yml")

first_year_cash_flow_results = FirstYearCashFlow.new(app_config).calculate
simulation_results = Simulator.new(app_config).run
evaluator_results = SimulationEvaluator.new(simulation_results, app_config).evaluate

formatter = SimulatorFormatter.new(simulation_results, first_year_cash_flow_results, evaluator_results)
formatter.print_all

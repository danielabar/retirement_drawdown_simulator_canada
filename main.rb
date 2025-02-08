# frozen_string_literal: true

require_relative "config/environment"

app_config = AppConfig.new("inputs.yml")

first_year_cash_flow_results = FirstYearCashFlow.new(app_config).calculate
simulation_results = Simulator.new(app_config).run

formatter = SimulatorFormatter.new(simulation_results, first_year_cash_flow_results)
formatter.print_all

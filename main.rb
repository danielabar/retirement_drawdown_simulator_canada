# frozen_string_literal: true

require_relative "config/environment"

plan = RetirementPlan.new("inputs.yml")
first_year_cash_flow_results = FirstYearCashFlow.new(plan).calculate
simulation_results = Simulator.new(plan).run
formatter = SimulatorFormatter.new(simulation_results, first_year_cash_flow_results)
formatter.print_all

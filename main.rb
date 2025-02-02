# frozen_string_literal: true

require_relative "config/environment"

plan = RetirementPlan.new("inputs.yml")
results = Simulator.new(plan).run
formatter = SimulatorFormatter.new(results)
formatter.print_all

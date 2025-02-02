# frozen_string_literal: true

require_relative "lib/retirement_plan"
require_relative "lib/simulator"
require_relative "lib/simulator_formatter"

plan = RetirementPlan.new("inputs.yml")
results = Simulator.new(plan).run
formatter = SimulatorFormatter.new(results)
formatter.print_all

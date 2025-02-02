require_relative 'lib/retirement_plan'
require_relative 'lib/simulator'

plan = RetirementPlan.new('inputs.yml')
simulator = Simulator.new(plan)
simulator.run

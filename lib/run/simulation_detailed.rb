# frozen_string_literal: true

module Run
  class SimulationDetailed
    def initialize(app_config)
      @app_config = app_config
    end

    def run
      first_year_cash_flow_results = FirstYearCashFlow.new(app_config).calculate
      # TODO: Maybe we should just access simulator.results instead of returning results from `run` method
      simulation_results = Simulation::Simulator.new(app_config).run
      # TODO: Evaluator should also move to simulator namespace
      # TODO: Consider accessing evaluator.results rather than returning from `evaluate` method
      evaluator_results = SimulationEvaluator.new(simulation_results, app_config).evaluate
      # TODO: Simulator Formatter should also move to simulator namespace and maybe call it ConsolePrinter
      SimulatorFormatter.new(simulation_results, first_year_cash_flow_results, evaluator_results).print_all
    end

    private

    attr_reader :app_config
  end
end

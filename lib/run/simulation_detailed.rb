# frozen_string_literal: true

module Run
  class SimulationDetailed
    def initialize(app_config)
      @app_config = app_config
    end

    def run
      first_year_cash_flow_results = FirstYearCashFlow.new(app_config).calculate
      simulation_results = Simulator.new(app_config).run
      evaluator_results = SimulationEvaluator.new(simulation_results, app_config).evaluate

      SimulatorFormatter.new(simulation_results, first_year_cash_flow_results, evaluator_results).print_all
    end

    private

    attr_reader :app_config
  end
end

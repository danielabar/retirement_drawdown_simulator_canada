# frozen_string_literal: true

module Simulation
  class SimulationEvaluator
    def initialize(simulation_yearly_results, app_config)
      @simulation_yearly_results = simulation_yearly_results
      @app_config = app_config
      @max_age = app_config["max_age"]
    end

    def evaluate
      withdrawal_rate = WithdrawalRateCalculator.new(app_config).calculate
      last_result = simulation_yearly_results.last

      if last_result[:age] < max_age
        return failure_due_to_max_age(last_result[:age]).merge(withdrawal_rate: withdrawal_rate)
      end

      success_or_failure_based_on_balance(last_result).merge(withdrawal_rate: withdrawal_rate)
    end

    private

    attr_reader :app_config, :max_age, :simulation_yearly_results

    def success_threshold
      app_config["success_factor"] * app_config["desired_spending"]
    end

    def success_or_failure_based_on_balance(last_result)
      if last_result[:total_balance] >= success_threshold
        { success: true, explanation: build_explanation("successful", last_result[:total_balance]) }
      else
        { success: false, explanation: build_explanation("failed", last_result[:total_balance], success_threshold) }
      end
    end

    def failure_due_to_max_age(age)
      { success: false, explanation: "Simulation failed. Max age #{max_age} not reached. Final age is #{age}." }
    end

    def build_explanation(status, total_balance, threshold = nil)
      if status == "successful"
        "Simulation #{status} with total balance of #{NumericFormatter.format_currency(total_balance)}."
      else
        "Simulation #{status}. Max age reached, but total balance of " \
          "#{NumericFormatter.format_currency(total_balance)} is below success " \
          "threshold of #{NumericFormatter.format_currency(threshold)}."
      end
    end
  end
end

# frozen_string_literal: true

module Simulation
  class SimulationEvaluator
    def initialize(simulation_results, app_config)
      @simulation_results = simulation_results
      @app_config = app_config
      @withdrawal_amounts = WithdrawalAmounts.new(app_config)
      @success_factor = app_config["success_factor"]
      @max_age = app_config["max_age"]
    end

    def evaluate
      withdrawal_rate = WithdrawalRateCalculator.new(app_config).calculate
      last_result = simulation_results.last

      if last_result[:age] < max_age
        return failure_due_to_max_age(last_result[:age]).merge(withdrawal_rate: withdrawal_rate)
      end

      success_or_failure_based_on_balance(last_result).merge(withdrawal_rate: withdrawal_rate)
    end

    private

    attr_reader :app_config, :withdrawal_amounts, :max_age, :simulation_results

    def success_or_failure_based_on_balance(last_result)
      if last_result[:total_balance] >= success_threshold
        { success: true, explanation: build_explanation("successful", last_result[:total_balance]) }
      else
        { success: false, explanation: build_explanation("failed", last_result[:total_balance], success_threshold) }
      end
    end

    def failure_due_to_max_age(age)
      { success: false, explanation: "Simulation failed. Max age #{@max_age} not reached. Final age is #{age}." }
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

    # TODO: Consider simplifying this to just desired_spending because that
    # doesn't depend on CPP, which in turn depends on current_age that we don't have here.
    def success_threshold
      case drawdown_phase
      when :rrsp then rrsp_threshold
      when :taxable then taxable_threshold
      when :tfsa then tfsa_threshold
      when :cash_cushion then cash_cushion_threshold
      else raise "Unknown drawdown phase: #{drawdown_phase}"
      end
    end

    def drawdown_phase
      case @simulation_results.last[:note]
      when /rrsp/ then :rrsp
      when /taxable/ then :taxable
      when /tfsa/ then :tfsa
      when /cash_cushion/ then :cash_cushion
      end
    end

    def rrsp_threshold
      @success_factor * withdrawal_amounts.annual_rrsp
    end

    def taxable_threshold
      @success_factor * withdrawal_amounts.annual_taxable
    end

    def tfsa_threshold
      @success_factor * withdrawal_amounts.annual_tfsa
    end

    def cash_cushion_threshold
      @success_factor * withdrawal_amounts.annual_cash_cushion
    end
  end
end

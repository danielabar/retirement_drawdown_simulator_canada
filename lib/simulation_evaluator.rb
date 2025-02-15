# frozen_string_literal: true

class SimulationEvaluator
  def initialize(simulation_results, app_config)
    @simulation_results = simulation_results
    @app_config = app_config
    @withdrawal_amounts = WithdrawalAmounts.new(app_config)
    @success_factor = app_config["success_factor"]
    @max_age = app_config["max_age"]
  end

  def evaluate
    last_result = @simulation_results.last
    return failure_due_to_max_age(last_result[:age]) if last_result[:age] < @max_age

    success_or_failure_based_on_balance(last_result)
  end

  private

  attr_reader :withdrawal_amounts

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

  # TODO: The notion of phases is not quite right now
  # that we could go back and withdraw from a previous account
  # if the balance has grown since we last left it.
  def success_threshold
    case drawdown_phase
    when :rrsp then rrsp_threshold
    when :taxable then taxable_threshold
    when :tfsa then tfsa_threshold
    else raise "Unknown drawdown phase: #{drawdown_phase}"
    end
  end

  # TODO: Does it even make sense to match on note?
  # Maybe should have something more precise to indicate what phase we were in?
  def drawdown_phase
    case @simulation_results.last[:note]
    when /rrsp/ then :rrsp
    when /taxable/ then :taxable
    when /tfsa/ then :tfsa
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
end

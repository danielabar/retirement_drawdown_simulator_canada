# frozen_string_literal: true

class SimulationEvaluator
  def initialize(results, app_config)
    @results = results
    @success_factor = app_config["success_factor"]
    @max_age = app_config["max_age"]
  end

  # TODO: Extract formatter from simulator_formatter private format_currency so can re-use it in explanation
  # TODO: Better explanation in failure case - comparing to what withdrawal amount
  # NOTE: It's currently possible to end simulation before max age even if total across all accounts is enough
  # for another year or so of spending, because program currently doesn't handle multi-account withdrawals in a given year.
  def evaluate
    last_result = @results.last
    if last_result[:age] >= @max_age && last_result[:total_balance] >= success_threshold
      { success: true, explanation: "Simulation successful with total balance of #{last_result[:total_balance]}." }
    else
      { success: false, explanation: "Simulation failed. Max age reached without sufficient balance." }
    end
  end

  private

  # TODO: Use WithdrawalAmountCalculator here, and everywhere that needs to know annual withdrawal amounts (such as simulator)
  def success_threshold
    last_result = @results.last
    case last_result[:note]
    when "RRSP Drawdown"
      @success_factor * @app_config["annual_withdrawal_amount_rrsp"]
    when "Taxable Drawdown"
      @success_factor * (@app_config["desired_spending"] + @app_config["annual_tfsa_contribution"])
    when "TFSA Drawdown"
      @success_factor * @app_config["desired_spending"]
    else
      0
    end
  end
end

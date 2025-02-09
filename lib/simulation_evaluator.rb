# frozen_string_literal: true

class SimulationEvaluator
  def initialize(simulation_results, app_config)
    @simulation_results = simulation_results
    @app_config = app_config
    @success_factor = app_config["success_factor"]
    @max_age = app_config["max_age"]
  end

  # TODO: Extract formatter from simulator_formatter private format_currency so can re-use it in explanation
  # TODO: Better explanation in failure case - comparing to what withdrawal amount
  # NOTE: It's currently possible to end simulation before max age even if total across all accounts is enough
  # for another year or so of spending, because program currently doesn't handle multi-account withdrawals in a year.
  def evaluate
    last_result = @simulation_results.last
    if last_result[:age] >= @max_age && last_result[:total_balance] >= success_threshold
      { success: true, explanation: "Simulation successful with total balance of #{last_result[:total_balance]}." }
    else
      { success: false, explanation: "Simulation failed. Max age reached without sufficient balance." }
    end
  end

  private

  # TODO: Rather than `note` which could also be something like `Exited TFSA Drawdown due to reaching max age`,
  # should introduce a `phase_name` instead in simulation_results, then check that here.
  # TODO: Use WithdrawalAmountCalculator here, and others that need annual withdrawal amounts (eg: simulator)
  def success_threshold
    last_result = @simulation_results.last
    case last_result[:note]
    when /RRSP Drawdown/
      @success_factor * @app_config["annual_withdrawal_amount_rrsp"]
    when /Taxable Drawdown/
      @success_factor * (@app_config["desired_spending"] + @app_config["annual_tfsa_contribution"])
    when /TFSA Drawdown/
      @success_factor * @app_config["desired_spending"]
    else
      raise "Unknown drawdown phase: #{last_result[:note]}"
    end
  end
end

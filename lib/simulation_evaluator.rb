# frozen_string_literal: true

class SimulationEvaluator
  def initialize(simulation_results, app_config)
    @simulation_results = simulation_results
    @app_config = app_config
    @success_factor = app_config["success_factor"]
    @max_age = app_config["max_age"]
  end

  # TODO: Extract formatter from simulator_formatter private format_currency so can re-use it in explanation
  def evaluate
    last_result = @simulation_results.last
    if last_result[:age] >= @max_age && last_result[:total_balance] >= success_threshold
      { success: true, explanation: "Simulation successful with total balance of #{last_result[:total_balance]}." }
    else
      { success: false, explanation: "Simulation failed. Max age reached without sufficient balance." }
    end
  end

  private

  def success_threshold
    case drawdown_phase
    when :rrsp then rrsp_threshold
    when :taxable then taxable_threshold
    when :tfsa then tfsa_threshold
    else raise "Unknown drawdown phase: #{drawdown_phase}"
    end
  end

  # TODO: Rather than `note` which could also be something like `Exited TFSA Drawdown due to reaching max age`,
  # should introduce a `phase_name` instead in simulation_results, then check that here to allow for more precision.
  def drawdown_phase
    case @simulation_results.last[:note]
    when /RRSP Drawdown/ then :rrsp
    when /Taxable Drawdown/ then :taxable
    when /TFSA Drawdown/ then :tfsa
    end
  end

  # TODO: Use WithdrawalAmountCalculator to determine the withdrawal amount
  def rrsp_threshold
    @success_factor * @app_config["annual_withdrawal_amount_rrsp"]
  end

  def taxable_threshold
    @success_factor * (@app_config["desired_spending"] + @app_config["annual_tfsa_contribution"])
  end

  def tfsa_threshold
    @success_factor * @app_config["desired_spending"]
  end
end

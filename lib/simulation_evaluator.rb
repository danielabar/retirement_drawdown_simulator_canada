# frozen_string_literal: true

class SimulationEvaluator
  def initialize(simulation_results, app_config)
    @simulation_results = simulation_results
    @app_config = app_config
    @success_factor = app_config["success_factor"]
    @max_age = app_config["max_age"]
  end

  def evaluate
    last_result = @simulation_results.last
    return failure_due_to_max_age(last_result[:age]) if last_result[:age] < @max_age

    success_or_failure_based_on_balance(last_result)
  end

  private

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
      "Simulation #{status} with total balance of #{total_balance}."
    else
      "Simulation #{status}. Max age reached, but total balance of #{total_balance} " \
        "is below success threshold of #{threshold}."
    end
  end

  def success_threshold
    case drawdown_phase
    when :rrsp then rrsp_threshold
    when :taxable then taxable_threshold
    when :tfsa then tfsa_threshold
    else raise "Unknown drawdown phase: #{drawdown_phase}"
    end
  end

  def drawdown_phase
    case @simulation_results.last[:note]
    when /RRSP Drawdown/ then :rrsp
    when /Taxable Drawdown/ then :taxable
    when /TFSA Drawdown/ then :tfsa
    end
  end

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

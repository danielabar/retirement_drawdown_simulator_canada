# frozen_string_literal: true

class SuccessRateResults
  def initialize(simulation_results)
    @simulation_results = simulation_results
  end

  def success_rate
    (successful_runs.to_f / total_runs)
  end

  def average_final_balance
    final_balances.sum.to_f / total_runs
  end

  def withdrawal_rate
    simulation_results.first[:withdrawal_rate] # Assuming consistent withdrawal rate
  end

  def percentiles
    sorted = final_balances.sort
    {
      p5: sorted.percentile(5),
      p10: sorted.percentile(10),
      p25: sorted.percentile(25),
      p50: sorted.percentile(50),
      p75: sorted.percentile(75),
      p90: sorted.percentile(90),
      p95: sorted.percentile(95)
    }
  end

  private

  attr_reader :simulation_results

  def successful_runs
    simulation_results.count { |result| result[:success] }
  end

  def total_runs
    simulation_results.size
  end

  def final_balances
    simulation_results.map { |result| result[:final_balance] }
  end
end

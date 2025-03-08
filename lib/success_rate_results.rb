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
      p5: percentile(sorted, 5),
      p10: percentile(sorted, 10),
      p25: percentile(sorted, 25),
      p50: percentile(sorted, 50),
      p75: percentile(sorted, 75),
      p90: percentile(sorted, 90),
      p95: percentile(sorted, 95)
    }
  end

  private

  attr_reader :simulation_results

  def successful_runs
    simulation_results.count { |result| result[:success] }
    # simulation_results.sum { |result| result[:success] }
  end

  def total_runs
    simulation_results.size
  end

  def final_balances
    simulation_results.map { |result| result[:final_balance] }
  end

  def percentile(sorted, p)
    index = (p * total_runs / 100.0).ceil - 1
    sorted[[index, 0].max] # Ensure index isn't negative
  end
end

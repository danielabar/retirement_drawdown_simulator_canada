# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe SuccessRateResults do
  subject(:results) { described_class.new(simulation_results) }

  let(:simulation_results) do
    [
      { success: true, withdrawal_rate: 0.04, final_balance: 900_000 },
      { success: true, withdrawal_rate: 0.04, final_balance: 1_500_000 },
      { success: true, withdrawal_rate: 0.04, final_balance: 2_100_000 },
      { success: false, withdrawal_rate: 0.04, final_balance: 1_200_000 }
    ]
  end

  describe "#success_rate" do
    it "calculates the proportion of successful runs" do
      expect(results.success_rate).to eq(0.75) # 3 out of 4 runs succeeded
    end
  end

  describe "#average_final_balance" do
    it "calculates the average final balance" do
      # (900_000 + 1_500_000 + 2_100_000 + 1_200_000) / 4 = 1_425_000
      expect(results.average_final_balance).to eq(1_425_000)
    end
  end

  describe "#withdrawal_rate" do
    it "returns the withdrawal rate from the first entry" do
      expect(results.withdrawal_rate).to eq(0.04)
    end
  end

  describe "#percentiles" do
    it "calculates correct percentiles for final balances" do
      expect(results.percentiles).to eq(
        {
          p5: 900_000,
          p10: 900_000,
          p25: 900_000,
          p50: 1_200_000,
          p75: 1_500_000,
          p90: 2_100_000,
          p95: 2_100_000
        }
      )
    end
  end
end

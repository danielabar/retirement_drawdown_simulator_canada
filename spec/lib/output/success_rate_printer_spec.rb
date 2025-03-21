# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe Output::SuccessRatePrinter do
  describe "#print_summary" do
    let(:simulation_results) do
      [
        { success: true, withdrawal_rate: 0.04, final_balance: 900_000 },
        { success: true, withdrawal_rate: 0.04, final_balance: 1_500_000 },
        { success: true, withdrawal_rate: 0.04, final_balance: 2_100_000 },
        { success: false, withdrawal_rate: 0.04, final_balance: 1_200_000 }
      ]
    end

    let(:success_rate_results) { SuccessRateResults.new(simulation_results) }
    let(:printer) { described_class.new(success_rate_results) }

    let(:expected_output) do
      <<~OUTPUT
        === Simulation Results ===

        Summary:
        ┌───────────────────────┬────────────┐
        │ Description           │     Amount │
        ├───────────────────────┼────────────┤
        │ Withdrawal Rate       │       4.0% │
        │ Success Rate          │      75.0% │
        │ Average Final Balance │ $1,425,000 │
        └───────────────────────┴────────────┘

        Final Balance Percentiles:
        ┌──────────────────────────┬────────────┐
        │ Description              │     Amount │
        ├──────────────────────────┼────────────┤
        │ 5th Percentile           │   $945,000 │
        │ 10th Percentile          │   $990,000 │
        │ 25th Percentile          │ $1,125,000 │
        │ 50th Percentile (Median) │ $1,350,000 │
        │ 75th Percentile          │ $1,650,000 │
        │ 90th Percentile          │ $1,920,000 │
        │ 95th Percentile          │ $2,010,000 │
        └──────────────────────────┴────────────┘
      OUTPUT
    end

    it "prints the success rate and percentile values correctly in tabular format" do
      expect { printer.print_summary }
        .to output(expected_output).to_stdout
    end
  end
end

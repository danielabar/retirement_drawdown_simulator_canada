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

    context "when annuity was skipped in some runs" do
      let(:simulation_results) do
        [
          { success: true, withdrawal_rate: 0.04, final_balance: 900_000, annuity_skipped: true },
          { success: true, withdrawal_rate: 0.04, final_balance: 1_500_000, annuity_skipped: false },
          { success: true, withdrawal_rate: 0.04, final_balance: 2_100_000, annuity_skipped: true },
          { success: false, withdrawal_rate: 0.04, final_balance: 1_200_000, annuity_skipped: false }
        ]
      end

      it "includes annuity skip warning with count and percentage" do
        output = capture_output { printer.print_summary }
        expect(output).to include("Annuity purchase skipped in 2 of 4 runs (50.0%)")
        expect(output).to include("RRSP balance was insufficient at purchase age")
      end
    end

    context "when no annuity skips occurred" do
      it "does not include annuity skip warning" do
        output = capture_output { printer.print_summary }
        expect(output).not_to include("Annuity purchase skipped")
      end
    end

    def capture_output
      original_stdout = $stdout
      $stdout = StringIO.new
      yield
      $stdout.string
    ensure
      $stdout = original_stdout
    end
  end
end

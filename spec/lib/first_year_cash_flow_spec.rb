# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe FirstYearCashFlow do
  subject(:first_year_cash_flow) { described_class.new(app_config).calculate }

  let(:app_config) do
    AppConfig.new(
      "mode" => "detailed",
      "retirement_age" => 60,
      "max_age" => 120,
      "province_code" => "ONT",
      "annual_tfsa_contribution" => 7_000,
      "desired_spending" => 40_000,
      "annual_growth_rate" => {
        "average" => 0.03,
        "min" => 0.03,
        "max" => 0.03,
        "downturn_threshold" => -0.1
      },
      "return_sequence_type" => "constant",
      "accounts" => {
        "rrsp" => 600_000,
        "taxable" => 400_000,
        "tfsa" => 120_000,
        "cash_cushion" => 0
      },
      "taxes" => {
        "rrsp_withholding_rate" => 0.3
      }
    )
  end

  describe "#calculate" do
    it "returns correct label-value pairs" do
      expected_output = [
        ["Desired Income Including TFSA Contribution", be_within(1).of(47_000)],
        ["RRSP Withdrawal Amount (higher due to income tax)", be_within(1).of(55_067)],
        ["RRSP Withholding Tax", be_within(1).of(16_520)],
        ["Actual Tax Bill", be_within(1).of(8_067)],
        ["Expected Tax Refund", be_within(1).of(8_453)],
        ["RRSP Available After Withholding", be_within(1).of(38_547)],
        ["Required Cash Buffer for First Year", be_within(1).of(8_453)]
      ]

      expect(first_year_cash_flow).to match_array(expected_output)
    end
  end
end

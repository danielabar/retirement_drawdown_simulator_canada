# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe WithdrawalAmounts do
  subject(:withdrawal_amounts) { described_class.new(app_config) }

  let(:app_config) do
    AppConfig.new(
      "retirement_age" => 65,
      "max_age" => 75,
      "province_code" => "ONT",
      "annual_tfsa_contribution" => 10,
      "desired_spending" => 30_000,
      "annual_growth_rate" => {
        "average" => 0.01,
        "min" => -0.1,
        "max" => 0.1,
        "downturn_threshold" => -0.1
      },
      "return_sequence_type" => "constant",
      "accounts" => {
        "rrsp" => 80_000,
        "taxable" => 60_000,
        "tfsa" => 30_000,
        "cash_cushion" => 0
      },
      "taxes" => {
        "rrsp_withholding_rate" => 0.3
      },
      "cpp" => {
        "start_age" => 65,
        "monthly_amount" => 0
      }
    )
  end

  before do
    withdrawal_amounts.current_age = 65
  end

  describe "#annual_rrsp" do
    it "returns the exact RRSP withdrawal amount from config" do
      expect(withdrawal_amounts.annual_rrsp).to eq(33_704.73)
    end
  end

  describe "#annual_taxable" do
    it "returns desired spending plus TFSA contribution" do
      expected_value = 30_000 + 10
      expect(withdrawal_amounts.annual_taxable).to eq(expected_value)
    end
  end

  describe "#annual_tfsa" do
    it "returns the exact desired spending amount" do
      expect(withdrawal_amounts.annual_tfsa).to eq(30_000)
    end
  end

  describe "annual_cash_cushion" do
    it "returns the exact desired spending amount" do
      expect(withdrawal_amounts.annual_cash_cushion).to eq(30_000)
    end
  end
end

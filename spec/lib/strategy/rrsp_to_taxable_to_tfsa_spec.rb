# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe Strategy::RrspToTaxableToTfsa do
  let(:app_config) do
    AppConfig.new(
      "retirement_age" => 65,
      "max_age" => 75,
      "annual_tfsa_contribution" => 10,
      "desired_spending" => 30_000,
      "annual_withdrawal_amount_rrsp" => 33_800,
      "annual_growth_rate" => {
        "average" => 0.01,
        "min" => -0.1,
        "max" => 0.1,
        "downturn_threshold" => -0.1
      },
      "accounts" => {
        "rrsp" => 80_000,
        "taxable" => 60_000,
        "tfsa" => 30_000,
        "cash_cushion" => 30_000
      },
      "taxes" => {
        "rrsp_withholding_rate" => 0.3,
        "actual_tax_bill" => 3_713
      }
    )
  end

  let(:strategy) { described_class.new(app_config) }

  describe "#select_account" do
    context "when market return is below downturn threshold and cash cushion has enough funds" do
      it "selects the cash cushion account" do
        expect(strategy.select_account(-0.15).name).to eq("cash_cushion")
      end
    end

    context "when market return is below downturn threshold and cash cushion does not have enough funds" do
      before { strategy.cash_cushion.withdraw(30_000) } # Empty Cash Cushion

      it "selects the rrsp account if it has sufficient balance" do
        expect(strategy.select_account(-0.15).name).to eq("rrsp")
      end
    end

    context "when RRSP has enough balance" do
      it "selects the RRSP account" do
        expect(strategy.select_account(0.05).name).to eq("rrsp")
      end
    end

    context "when RRSP is insufficient but taxable has enough balance" do
      before { strategy.rrsp_account.withdraw(80_000) } # Empty RRSP

      it "selects the taxable account" do
        expect(strategy.select_account(0.05).name).to eq("taxable")
      end
    end

    context "when RRSP and taxable are insufficient, but TFSA has enough balance" do
      before do
        strategy.rrsp_account.withdraw(80_000) # Empty RRSP
        strategy.taxable_account.withdraw(60_000) # Empty taxable
      end

      it "selects the TFSA account" do
        expect(strategy.select_account(0.05).name).to eq("tfsa")
      end
    end

    context "when all accounts are depleted" do
      before do
        strategy.rrsp_account.withdraw(80_000)
        strategy.taxable_account.withdraw(60_000)
        strategy.tfsa_account.withdraw(30_000)
        strategy.cash_cushion.withdraw(10_000)
      end

      it "returns nil" do
        expect(strategy.select_account(0.05)).to be_nil
      end
    end
  end
end

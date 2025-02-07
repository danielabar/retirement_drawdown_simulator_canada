# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe RetirementPlan do
  let(:config_path) { File.join(__dir__, "..", "fixtures", "example_input_low_growth.yml") }
  let(:plan) { described_class.new(config_path) }

  describe "instance variables" do
    it "loads retirement age from input file" do
      expect(plan.retirement_age).to eq(60)
    end

    it "loads annual TFSA contribution from input file" do
      expect(plan.annual_tfsa_contribution).to eq(7000)
    end

    it "loads desired spending from input file" do
      expect(plan.desired_spending).to eq(40_000)
    end

    it "loads RRSP annual withdrawal amount from input file" do
      expect(plan.annual_withdrawal_amount_rrsp).to eq(56_000)
    end

    it "loads tax rates and actual tax bill from input file" do
      expect(plan.rrsp_withholding_tax_rate).to eq(0.3)
      expect(plan.actual_tax_bill).to eq(6360)
    end

    it "loads investment values from input file" do
      expect(plan.market_price).to eq(35.12)
      expect(plan.cost_per_share).to eq(29.34)
    end
  end

  describe "calculations" do
    it "calculates desired income based on spending and annual TFSA contribution" do
      expect(plan.desired_income).to eq(47_000) # 40000 + 7000
    end

    it "calculates RRSP tax withholding based on desired income and RRSP withholding rate" do
      expect(plan.tax_withholding).to eq(47_000 * 0.3) # 14100
    end

    it "calculates RRSP withdrawal actual amount available based on desired income and tax withholding" do
      expect(plan.rrsp_withdrawal_actual_amount_available).to eq(56_000 - 14_100) # 41900
    end

    it "calculates expected tax refund based on actual tax bill and tax withholding" do
      expect(plan.expected_refund).to eq(14_100 - 6360) # 7740
    end

    it "calculates RRSP amount available in subsequent years" do
      expect(plan.amount_available_subsequent_years).to eq(41_900 + 7740) # 49640
    end

    it "calculates capital gains tax" do
      acb_per_share = 35.12 - 29.34 # 5.78
      total_acb = acb_per_share * (47_000 / 35.12) # 7750.71
      capital_gains_tax = (total_acb / 2).round(2) # 3875.36
      expect(plan.capital_gains_tax).to eq(capital_gains_tax)
    end

    it "returns the annual withdrawal amount for taxable account based on desired income" do
      expect(plan.annual_withdrawal_amount_taxable).to eq(47_000)
    end

    it "returns the annual withdrawal amount for TFSA from input file" do
      expect(plan.annual_withdrawal_amount_tfsa).to eq(40_000)
    end
  end
end

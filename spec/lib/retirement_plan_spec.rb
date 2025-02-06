# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe RetirementPlan do
  let(:config_path) { File.join(__dir__, "..", "fixtures", "example_input_low_growth.yml") }
  let(:plan) { described_class.new(config_path) }

  describe "instance variables" do
    it "loads the correct retirement age" do
      expect(plan.retirement_age).to eq(60)
    end

    it "loads the correct annual TFSA contribution" do
      expect(plan.annual_tfsa_contribution).to eq(7000)
    end

    it "loads the correct desired spending" do
      expect(plan.desired_spending).to eq(40_000)
    end

    it "loads the correct annual withdrawal amount for RRSP" do
      expect(plan.annual_withdrawal_amount_rrsp).to eq(56_000)
    end

    it "loads the correct tax rates and actual tax bill" do
      expect(plan.rrsp_withholding_tax_rate).to eq(0.3)
      expect(plan.actual_tax_bill).to eq(6360)
    end

    it "loads the correct investment values" do
      expect(plan.market_price).to eq(35.12)
      expect(plan.cost_per_share).to eq(29.34)
    end
  end

  describe "growth rate loading" do
    it "initializes ReturnSequence with correct growth rates" do
      return_sequence_mock = instance_double(ReturnSequence)

      # Use `allow` to stub the method
      allow(ReturnSequence).to receive(:new).and_return(return_sequence_mock)

      # Trigger the RetirementPlan initialization
      described_class.new(config_path)

      # Verify the method was called with the expected arguments
      expect(ReturnSequence).to have_received(:new).with(
        60,    # retirement_age
        120,   # max_age
        0.03,  # average growth
        0.03,  # min growth
        0.03   # max growth
      )
    end
  end

  describe "calculations" do
    it "calculates the correct desired income" do
      expect(plan.desired_income).to eq(47_000) # 40000 + 7000
    end

    it "calculates the correct RRSP tax withholding" do
      expect(plan.tax_withholding).to eq(47_000 * 0.3) # 14100
    end

    it "calculates the correct RRSP withdrawal actual amount available" do
      expect(plan.rrsp_withdrawal_actual_amount_available).to eq(56_000 - 14_100) # 41900
    end

    it "calculates the correct expected tax refund" do
      expect(plan.expected_refund).to eq(14_100 - 6360) # 7740
    end

    it "calculates the correct amount available in subsequent years" do
      expect(plan.amount_available_subsequent_years).to eq(41_900 + 7740) # 49640
    end

    it "calculates the correct capital gains tax" do
      acb_per_share = 35.12 - 29.34 # 5.78
      total_acb = acb_per_share * (47_000 / 35.12) # 7750.71
      capital_gains_tax = (total_acb / 2).round(2) # 3875.36
      expect(plan.capital_gains_tax).to eq(capital_gains_tax)
    end

    it "returns the correct annual withdrawal amounts" do
      expect(plan.annual_withdrawal_amount_taxable).to eq(47_000)
      expect(plan.annual_withdrawal_amount_tfsa).to eq(40_000)
    end
  end
end

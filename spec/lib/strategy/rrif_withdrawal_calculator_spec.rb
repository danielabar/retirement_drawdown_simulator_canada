# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe Strategy::RRIFWithdrawalCalculator do
  let(:calculator) { described_class.new }
  let(:account_balance) { 100_000 }

  describe "#withdrawal_amount" do
    it "calculates withdrawal for age 71" do
      expect(calculator.withdrawal_amount(71, account_balance)).to be_within(0.01).of(5280)
    end

    it "calculates withdrawal for age 85" do
      expect(calculator.withdrawal_amount(85, account_balance)).to be_within(0.01).of(8510)
    end

    it "calculates withdrawal for age 95" do
      expect(calculator.withdrawal_amount(95, account_balance)).to be_within(0.01).of(20_000)
    end

    it "defaults to age 95 rate for age over 95" do
      expect(calculator.withdrawal_amount(100, account_balance)).to be_within(0.01).of(20_000)
    end

    it "returns 0 for age below 71" do
      expect(calculator.withdrawal_amount(65, account_balance)).to eq(0)
    end
  end

  describe "#mandatory_withdrawal?" do
    it "returns true for age 71" do
      expect(calculator.mandatory_withdrawal?(71)).to be true
    end

    it "returns false for age below 71" do
      expect(calculator.mandatory_withdrawal?(65)).to be false
    end
  end
end

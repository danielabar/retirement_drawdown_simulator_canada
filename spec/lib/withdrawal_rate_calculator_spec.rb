# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe WithdrawalRateCalculator do
  subject(:calculator) { described_class.new(app_config) }

  let(:app_config) do
    AppConfig.new(
      "desired_spending" => 40_000,
      "accounts" => {
        "rrsp" => 400_000,
        "taxable" => 300_000,
        "tfsa" => 300_000
      }
    )
  end

  describe "#calculate" do
    context "when total account balances sum to $1,000,000" do
      it "returns a withdrawal rate of 0.04 (4%)" do
        expect(calculator.calculate).to be_within(0.0001).of(0.04)
      end
    end

    context "when all accounts have a balance of zero" do
      let(:app_config) do
        AppConfig.new(
          "desired_spending" => 40_000,
          "accounts" => {
            "rrsp" => 0,
            "taxable" => 0,
            "tfsa" => 0
          }
        )
      end

      it "returns 0.0" do
        expect(calculator.calculate).to eq(0.0)
      end
    end

    context "when only one account has a balance" do
      let(:app_config) do
        AppConfig.new(
          "desired_spending" => 40_000,
          "accounts" => {
            "rrsp" => 100_000,
            "taxable" => 0,
            "tfsa" => 0
          }
        )
      end

      it "returns a withdrawal rate of 0.4 (40%)" do
        expect(calculator.calculate).to be_within(0.0001).of(0.4)
      end
    end
  end
end

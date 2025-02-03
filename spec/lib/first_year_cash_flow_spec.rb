# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe FirstYearCashFlow do
  subject(:first_year_cash_flow) { described_class.new(plan).calculate }

  let(:config_path) { File.join(__dir__, "..", "fixtures", "example_input.yml") }
  let(:plan) { RetirementPlan.new(config_path) }

  describe "#calculate" do
    it "returns correct label-value pairs" do
      expected_output = [
        ["Desired Income Including TFSA Contribution", 47_000], # 40,000 + 7,000
        ["RRSP Withholding Tax", 16_800], # 56,000 * 0.30
        ["Expected Tax Refund", 10_440], # 16,800 - 6,360
        ["RRSP Available After Withholding", 39_200], # 56,000 - 16,800
        ["Required Cash Buffer for First Year", 7_800] # 40,000 - 39,200
      ]

      expect(first_year_cash_flow).to eq(expected_output)
    end
  end
end

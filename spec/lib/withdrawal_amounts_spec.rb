# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe WithdrawalAmounts do
  subject(:withdrawal_amounts) { described_class.new(app_config) }

  let(:app_config) { AppConfig.new(File.join(__dir__, "..", "fixtures", "example_input_minimal.yml")) }

  describe "#annual_rrsp" do
    it "returns the exact RRSP withdrawal amount from config" do
      # this is the reverse tax calculator amount based on desired_spending, tfsa contribution, and province_code
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
end

# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Simulator do
  let(:config_path) { File.join(__dir__, "..", "fixtures", "example_input.yml") }
  let(:plan) { RetirementPlan.new(config_path) }

  describe "#run" do
    it "simulates RRSP drawdown until balance is less than withdrawal amount" do
      results = described_class.new(plan).run

      final_rrsp_year = results.reverse.find { |r| r[:note] == "RRSP Drawdown" }
      expect(final_rrsp_year[:rrsp_balance]).to be < plan.annual_withdrawal_amount_rrsp
    end

    it "simulates taxable drawdown until balance is below the withdrawal amount" do
      results = described_class.new(plan).run

      final_taxable_year = results.reverse.find { |r| r[:note] == "Taxable Drawdown" }
      expect(final_taxable_year[:taxable_balance]).to be < plan.annual_withdrawal_amount_taxable
    end

    it "simulates TFSA drawdown until balance is depleted" do
      results = described_class.new(plan).run

      final_year = results.select { |r| r[:type] == :yearly_status }.last
      expect(final_year[:tfsa_balance]).to be < plan.annual_withdrawal_amount_tfsa
    end

    it "supports desired income withdrawals up to age 101" do
      results = described_class.new(plan).run
      expect(results.select { |r| r[:type] == :yearly_status }.last[:age]).to be <= 101
    end
  end
end

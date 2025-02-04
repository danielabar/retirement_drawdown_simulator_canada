# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Simulator do
  describe "#run" do
    context "when there are minimal balances to deplete quickly" do
      let(:config_path) { File.join(__dir__, "..", "fixtures", "example_input_minimal.yml") }
      let(:plan) { RetirementPlan.new(config_path) }
      let!(:results) { described_class.new(plan).run }

      it "simulation runs up to age 69" do
        expect(results.select { |r| r[:type] == :yearly_status }.last[:age]).to eq(69)
      end

      it "verifies withdrawals for age 65" do
        row = results.find { |r| r[:age] == 65 }
        expect(row).to match(
          a_hash_including(
            age: 65,
            rrsp_balance: be_within(1).of(46_662),
            tfsa_balance: be_within(1).of(30_310),
            taxable_balance: be_within(1).of(60_600),
            note: "RRSP Drawdown",
            type: :yearly_status
          )
        )
      end

      it "verifies the expected values for age 66" do
        row = results.find { |r| r[:age] == 66 }
        expect(row).to match(
          a_hash_including(
            age: 66,
            rrsp_balance: be_within(1).of(12_990),
            tfsa_balance: be_within(1).of(30_623),
            taxable_balance: be_within(1).of(61_206),
            note: "RRSP Drawdown",
            type: :yearly_status
          )
        )
      end

      it "verifies the expected values for age 67" do
        row = results.find { |r| r[:age] == 67 }
        expect(row).to match(
          a_hash_including(
            age: 67,
            rrsp_balance: be_within(1).of(13_120),
            tfsa_balance: be_within(1).of(30_939),
            taxable_balance: be_within(1).of(31_507),
            note: "Taxable Drawdown",
            type: :yearly_status
          )
        )
      end

      it "verifies the expected values for age 68" do
        row = results.find { |r| r[:age] == 68 }
        expect(row).to match(
          a_hash_including(
            age: 68,
            rrsp_balance: be_within(1).of(13_251),
            tfsa_balance: be_within(1).of(31_259),
            taxable_balance: be_within(1).of(1_512),
            note: "Taxable Drawdown",
            type: :yearly_status
          )
        )
      end

      it "verifies the expected values for age 69" do
        row = results.find { |r| r[:age] == 69 }
        expect(row).to match(
          a_hash_including(
            age: 69,
            rrsp_balance: be_within(1).of(13_384),
            tfsa_balance: be_within(1).of(1_271),
            taxable_balance: be_within(1).of(1_528),
            note: "TFSA Drawdown",
            type: :yearly_status
          )
        )
      end
    end

    context "when there is a low growth rate" do
      let(:config_path) { File.join(__dir__, "..", "fixtures", "example_input_low_growth.yml") }
      let(:plan) { RetirementPlan.new(config_path) }

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

    context "when there is a high growth rate" do
      let(:config_path) { File.join(__dir__, "..", "fixtures", "example_input_high_growth.yml") }
      let(:plan) { RetirementPlan.new(config_path) }

      it "exits TFSA drawdown early" do
        results = described_class.new(plan).run
        expect(results.select do |r|
          r[:type] == :yearly_status
        end.last[:note]).to eq("Exited TFSA Drawdown due to reaching max age")
      end

      it "supports desired income withdrawals to at least max age" do
        results = described_class.new(plan).run
        expect(results.select { |r| r[:type] == :yearly_status }.last[:age]).to be >= plan.max_age
      end
    end
  end
end

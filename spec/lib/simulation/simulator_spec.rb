# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe Simulation::Simulator do
  let(:base_fixture_path) { File.expand_path("../../fixtures", __dir__) }

  describe "#run" do
    context "when there are minimal balances to deplete quickly" do
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
      let!(:results) { described_class.new(app_config).run }

      it "simulation runs up to age 69" do
        expect(results.last[:age]).to eq(69)
      end

      it "verifies withdrawals for age 65" do
        row = results.find { |r| r[:age] == 65 }
        expect(row).to match(
          a_hash_including(
            age: 65,
            rrsp_balance: be_within(1).of(46_758),
            tfsa_balance: be_within(1).of(30_310),
            taxable_balance: be_within(1).of(60_600),
            note: "rrsp",
            rate_of_return: 0.01,
            total_balance: be_within(1).of(137_668.32)
          )
        )
      end

      it "verifies the expected values for age 66" do
        row = results.find { |r| r[:age] == 66 }
        expect(row).to match(
          a_hash_including(
            age: 66,
            rrsp_balance: be_within(1).of(13_184),
            tfsa_balance: be_within(1).of(30_623),
            taxable_balance: be_within(1).of(61_206),
            note: "rrsp",
            rate_of_return: 0.01,
            total_balance: be_within(1).of(105_013.33)
          )
        )
      end

      it "verifies the expected values for age 67" do
        row = results.find { |r| r[:age] == 67 }
        expect(row).to match(
          a_hash_including(
            age: 67,
            rrsp_balance: be_within(1).of(13_316),
            tfsa_balance: be_within(1).of(30_940),
            taxable_balance: be_within(1).of(31_508),
            note: "taxable",
            rate_of_return: 0.01,
            total_balance: be_within(1).of(75_763.46)
          )
        )
      end

      it "verifies the expected values for age 68" do
        row = results.find { |r| r[:age] == 68 }
        expect(row).to match(
          a_hash_including(
            age: 68,
            rrsp_balance: be_within(1).of(13_449),
            tfsa_balance: be_within(1).of(31_259),
            taxable_balance: be_within(1).of(1_513),
            note: "taxable",
            rate_of_return: 0.01,
            total_balance: be_within(1).of(46_221.10)
          )
        )
      end

      it "verifies the expected values for age 69" do
        row = results.find { |r| r[:age] == 69 }
        expect(row).to match(
          a_hash_including(
            age: 69,
            rrsp_balance: be_within(1).of(13_584),
            tfsa_balance: be_within(1).of(1_272),
            taxable_balance: be_within(1).of(1_528),
            note: "tfsa",
            rate_of_return: 0.01,
            total_balance: be_within(1).of(16_383.31)
          )
        )
      end
    end

    context "when there is a low growth rate" do
      let(:app_config) do
        AppConfig.new(
          "mode" => "detailed",
          "retirement_age" => 60,
          "max_age" => 120,
          "province_code" => "ONT",
          "annual_tfsa_contribution" => 7_000,
          "desired_spending" => 40_000,
          "annual_growth_rate" => {
            "average" => 0.03,
            "min" => 0.03,
            "max" => 0.03,
            "downturn_threshold" => -0.1
          },
          "return_sequence_type" => "constant",
          "accounts" => {
            "rrsp" => 600_000,
            "taxable" => 400_000,
            "tfsa" => 120_000,
            "cash_cushion" => 0
          },
          "cpp" => {
            "start_age" => 65,
            "monthly_amount" => 0
          },
          "taxes" => {
            "rrsp_withholding_rate" => 0.3
          }
        )
      end

      let!(:results) { described_class.new(app_config).run }

      it "simulates RRSP drawdown until balance is less than withdrawal amount" do
        final_rrsp_year = results.reverse.find { |r| r[:note] == "rrsp" }
        expect(final_rrsp_year[:rrsp_balance]).to be < app_config["desired_spending"]
      end

      it "simulates taxable drawdown until balance is below the withdrawal amount" do
        final_taxable_year = results.reverse.find { |r| r[:note] == "taxable" }
        expect(final_taxable_year[:taxable_balance]).to be < 47_000
      end

      it "simulates TFSA drawdown until balance is depleted" do
        final_year = results.last
        expect(final_year[:tfsa_balance]).to be < 40_000
      end

      it "supports desired income withdrawals up to age 105" do
        expect(results.last[:age]).to eq 105
      end
    end

    context "when there is a high growth rate" do
      let(:app_config) do
        AppConfig.new(
          "mode" => "detailed",
          "retirement_age" => 60,
          "max_age" => 120,
          "province_code" => "ONT",
          "annual_tfsa_contribution" => 7_000,
          "desired_spending" => 40_000,
          "annual_growth_rate" => {
            "average" => 0.1,
            "min" => 0.1,
            "max" => 0.1,
            "downturn_threshold" => -0.1
          },
          "return_sequence_type" => "constant",
          "accounts" => {
            "rrsp" => 600_000,
            "taxable" => 400_000,
            "tfsa" => 120_000,
            "cash_cushion" => 0
          },
          "cpp" => {
            "start_age" => 65,
            "monthly_amount" => 0
          },
          "taxes" => {
            "rrsp_withholding_rate" => 0.3
          }
        )
      end

      let!(:results) { described_class.new(app_config).run }

      it "supports desired income withdrawals to max age" do
        expect(results.last[:age]).to eq 120 # max age from fixture
      end
    end
  end
end

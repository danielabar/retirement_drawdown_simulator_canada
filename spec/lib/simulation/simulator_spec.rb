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

      let!(:simulation_output) { described_class.new(app_config).run }
      let!(:yearly_results) { simulation_output[:yearly_results] }

      it "includes oas as false in yearly results when oas is not configured" do
        row = yearly_results.find { |r| r[:age] == 65 }
        expect(row[:oas]).to be(false)
      end

      it "simulation runs up to age 69" do
        expect(yearly_results.last[:age]).to eq(69)
      end

      it "exposes return_sequence with one entry per simulated age matching yearly :rate_of_return" do
        return_sequence = simulation_output[:return_sequence]
        expect(return_sequence).to be_a(Hash)
        yearly_results.each do |row|
          expect(return_sequence[row[:age]]).to eq(row[:rate_of_return])
        end
      end

      it "verifies withdrawals for age 65" do
        row = yearly_results.find { |r| r[:age] == 65 }
        expect(row).to match(
          a_hash_including(
            age: 65,
            rrsp_balance: be_within(1).of(46_758),
            tfsa_balance: be_within(1).of(30_310),
            taxable_balance: be_within(1).of(60_600),
            note: "rrsp",
            rate_of_return: 0.01,
            total_balance: be_within(1).of(137_668.32),
            rrif_forced_net_excess: 0
          )
        )
      end

      it "verifies the expected values for age 66" do
        row = yearly_results.find { |r| r[:age] == 66 }
        expect(row).to match(
          a_hash_including(
            age: 66,
            rrsp_balance: be_within(1).of(13_184),
            tfsa_balance: be_within(1).of(30_623),
            taxable_balance: be_within(1).of(61_206),
            note: "rrsp",
            rate_of_return: 0.01,
            total_balance: be_within(1).of(105_013.33),
            rrif_forced_net_excess: 0
          )
        )
      end

      it "verifies the expected values for age 67" do
        row = yearly_results.find { |r| r[:age] == 67 }
        expect(row).to match(
          a_hash_including(
            age: 67,
            rrsp_balance: be_within(1).of(0.0),
            tfsa_balance: be_within(1).of(30_939.63),
            taxable_balance: be_within(1).of(44_801.54),
            note: "rrsp, taxable",
            rate_of_return: 0.01,
            total_balance: be_within(1).of(75_741.17),
            rrif_forced_net_excess: 0
          )
        )
      end

      it "verifies the expected values for age 68" do
        row = yearly_results.find { |r| r[:age] == 68 }
        expect(row).to match(
          a_hash_including(
            age: 68,
            rrsp_balance: be_within(1).of(0.0),
            tfsa_balance: be_within(1).of(31_259.13),
            taxable_balance: be_within(1).of(14_939.45),
            note: "taxable",
            rate_of_return: 0.01,
            total_balance: be_within(1).of(46_198.58),
            rrif_forced_net_excess: 0
          )
        )
      end

      it "verifies the expected values for age 69" do
        row = yearly_results.find { |r| r[:age] == 69 }
        expect(row).to match(
          a_hash_including(
            age: 69,
            rrsp_balance: be_within(1).of(0.0),
            tfsa_balance: be_within(1).of(16_360.57),
            taxable_balance: be_within(1).of(0.0),
            note: "taxable, tfsa",
            rate_of_return: 0.01,
            total_balance: be_within(1).of(16_360.57),
            rrif_forced_net_excess: 0
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

      let!(:yearly_results) { described_class.new(app_config).run[:yearly_results] }

      it "when rrsp doesn't have enough, combines withdrawals with taxable" do
        rrsp_taxable_combined = yearly_results.find { |r| r[:note] == "rrsp, taxable" }
        expect(rrsp_taxable_combined[:rrsp_balance]).to eq 0.0
      end

      it "when taxable doesn't have enough, combines withdrawals with tfsa" do
        taxable_tfsa_combined = yearly_results.find { |r| r[:note] == "taxable, tfsa" }
        expect(taxable_tfsa_combined[:taxable_balance]).to eq 0.0
      end

      it "simulates TFSA drawdown until balance is below desired spending" do
        final_year = yearly_results.last
        expect(final_year[:tfsa_balance]).to be < 40_000
      end

      it "supports desired income withdrawals up to age 106" do
        expect(yearly_results.last[:age]).to eq 106
      end
    end

    context "when annuity is purchased at retirement age" do
      let(:app_config) do
        AppConfig.new(
          "retirement_age" => 65,
          "max_age" => 75,
          "province_code" => "ONT",
          "annual_tfsa_contribution" => 0,
          "desired_spending" => 30_000,
          "annual_growth_rate" => {
            "average" => 0.01,
            "min" => -0.1,
            "max" => 0.1,
            "downturn_threshold" => -0.1
          },
          "return_sequence_type" => "constant",
          "accounts" => {
            "rrsp" => 200_000,
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
          },
          "annuity" => {
            "purchase_age" => 65,
            "lump_sum" => 50_000,
            "monthly_payment" => 290
          }
        )
      end

      let!(:simulation_output) { described_class.new(app_config).run }
      let!(:yearly_results) { simulation_output[:yearly_results] }

      it "records annuity as true in yearly results from purchase age onward" do
        yearly_results.each do |row|
          expect(row[:annuity]).to be(true)
        end
      end

      it "shows RRSP balance reduced by lump sum plus withdrawal at age 65" do
        row = yearly_results.find { |r| r[:age] == 65 }
        # RRSP starts at 200K, lump sum of 50K taken out, then normal withdrawal occurs
        # RRSP after purchase: 150_000, then withdrawal + growth
        expect(row[:rrsp_balance]).to be < 150_000
      end

      it "records annuity as false when not configured" do
        no_annuity_config = AppConfig.new(app_config.data.except("annuity"))
        results = described_class.new(no_annuity_config).run[:yearly_results]
        results.each do |row|
          expect(row[:annuity]).to be(false)
        end
      end
    end

    context "when annuity is purchased mid-retirement" do
      let(:app_config) do
        AppConfig.new(
          "retirement_age" => 60,
          "max_age" => 75,
          "province_code" => "ONT",
          "annual_tfsa_contribution" => 0,
          "desired_spending" => 30_000,
          "annual_growth_rate" => {
            "average" => 0.03,
            "min" => -0.1,
            "max" => 0.1,
            "downturn_threshold" => -0.1
          },
          "return_sequence_type" => "constant",
          "accounts" => {
            "rrsp" => 400_000,
            "taxable" => 100_000,
            "tfsa" => 50_000,
            "cash_cushion" => 0
          },
          "taxes" => {
            "rrsp_withholding_rate" => 0.3
          },
          "cpp" => {
            "start_age" => 65,
            "monthly_amount" => 0
          },
          "annuity" => {
            "purchase_age" => 65,
            "lump_sum" => 100_000,
            "monthly_payment" => 580
          }
        )
      end

      let!(:yearly_results) { described_class.new(app_config).run[:yearly_results] }

      it "records annuity as false before purchase age" do
        pre_purchase = yearly_results.select { |r| r[:age] < 65 }
        pre_purchase.each do |row|
          expect(row[:annuity]).to be(false)
        end
      end

      it "records annuity as true from purchase age onward" do
        post_purchase = yearly_results.select { |r| r[:age] >= 65 }
        post_purchase.each do |row|
          expect(row[:annuity]).to be(true)
        end
      end
    end

    context "when annuity purchase is skipped due to insufficient RRSP" do
      let(:app_config) do
        AppConfig.new(
          "retirement_age" => 60,
          "max_age" => 70,
          "province_code" => "ONT",
          "annual_tfsa_contribution" => 0,
          "desired_spending" => 30_000,
          "annual_growth_rate" => {
            "average" => 0.01,
            "min" => -0.1,
            "max" => 0.1,
            "downturn_threshold" => -0.1
          },
          "return_sequence_type" => "constant",
          "accounts" => {
            "rrsp" => 200_000,
            "taxable" => 100_000,
            "tfsa" => 50_000,
            "cash_cushion" => 0
          },
          "taxes" => {
            "rrsp_withholding_rate" => 0.3
          },
          "cpp" => {
            "start_age" => 65,
            "monthly_amount" => 0
          },
          "annuity" => {
            "purchase_age" => 65,
            "lump_sum" => 500_000,
            "monthly_payment" => 2_900
          }
        )
      end

      let!(:yearly_results) { described_class.new(app_config).run[:yearly_results] }

      it "completes without error" do
        expect(yearly_results).not_to be_empty
      end

      it "records annuity as false in all yearly results" do
        yearly_results.each do |row|
          expect(row[:annuity]).to be(false)
        end
      end

      it "records annuity_purchase_skipped as false before purchase age" do
        pre_purchase = yearly_results.select { |r| r[:age] < 65 }
        pre_purchase.each do |row|
          expect(row[:annuity_purchase_skipped]).to be(false)
        end
      end

      it "records annuity_purchase_skipped as true from purchase age onward" do
        post_purchase = yearly_results.select { |r| r[:age] >= 65 }
        post_purchase.each do |row|
          expect(row[:annuity_purchase_skipped]).to be(true)
        end
      end

      it "includes 'annuity purchase skipped' in the note at purchase age only" do
        purchase_row = yearly_results.find { |r| r[:age] == 65 }
        expect(purchase_row[:note]).to include("annuity purchase skipped")

        yearly_results.select { |r| r[:age] > 65 }.each do |row|
          expect(row[:note]).not_to include("annuity purchase skipped")
        end
      end

      it "does not reduce RRSP balance by the lump sum at purchase age" do
        before_purchase = yearly_results.find { |r| r[:age] == 64 }
        at_purchase = yearly_results.find { |r| r[:age] == 65 }
        # RRSP should not drop by 500K — it only decreases from normal withdrawals
        expect(before_purchase[:rrsp_balance] - at_purchase[:rrsp_balance]).to be < 500_000
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

      let!(:yearly_results) { described_class.new(app_config).run[:yearly_results] }

      it "supports desired income withdrawals to max age" do
        yearly_results
        expect(yearly_results.last[:age]).to eq 120
      end
    end
  end
end

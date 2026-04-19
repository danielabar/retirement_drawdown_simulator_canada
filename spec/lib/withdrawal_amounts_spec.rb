# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe WithdrawalAmounts do
  subject(:withdrawal_amounts) { described_class.new(app_config) }

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
      },
      "oas" => {
        "start_age" => 65,
        "years_in_canada_after_18" => 0
      }
    )
  end

  context "when user is not taking CPP" do
    before { withdrawal_amounts.current_age = 65 }

    describe "#annual_rrsp" do
      it "returns the RRSP withdrawal amount needed to meet spending needs accounting for income taxes" do
        expect(withdrawal_amounts.annual_rrsp).to eq(33_704.73)
      end

      it "returns the RRSP withdrawal amount excluding tfsa contribution" do
        expect(withdrawal_amounts.annual_rrsp(exclude_tfsa_contribution: true)).to eq(33_692.22)
      end
    end

    describe "#annual_taxable" do
      it "returns desired spending plus TFSA contribution" do
        expect(withdrawal_amounts.annual_taxable).to eq(30_010)
      end

      it "returns desired spending excluding TFSA contribution" do
        expect(withdrawal_amounts.annual_taxable(exclude_tfsa_contribution: true)).to eq(30_000)
      end
    end

    describe "#annual_tfsa" do
      it "returns the desired spending amount" do
        expect(withdrawal_amounts.annual_tfsa).to eq(30_000)
      end
    end

    describe "#annual_cash_cushion" do
      it "returns the desired spending amount" do
        expect(withdrawal_amounts.annual_cash_cushion).to eq(30_000)
      end
    end
  end

  context "when user is taking CPP and is at or over the CPP start age" do
    before do
      app_config.cpp["monthly_amount"] = 1_000
      withdrawal_amounts.current_age = 65
    end

    describe "#annual_rrsp" do
      it "adjusts RRSP withdrawals to account for CPP and income taxes" do
        # i.e. 21_705.46 + 12_000 (cpp) = 33_705.46
        # and running that gross number through the income tax calculator
        # results in a take home of just over 30_000 which is what we want
        expect(withdrawal_amounts.annual_rrsp).to be_within(0.01).of(21_705.46)
      end
    end

    describe "#annual_taxable" do
      # In this case, cpp gross income of 1_000 * 12 = 12_000,
      # which is well within the basic personal credit so this
      # amount is not subject to income tax. Therefore we can
      # subtract that from our usual withdrawals.

      it "reduces taxable withdrawals by net CPP income" do
        expect(withdrawal_amounts.annual_taxable).to eq(18_010)
      end
    end

    describe "#annual_tfsa" do
      it "reduces TFSA withdrawals by net CPP income" do
        expect(withdrawal_amounts.annual_tfsa).to eq(18_000)
      end
    end

    describe "#annual_cash_cushion" do
      it "reduces cash cushion withdrawals by net CPP income" do
        expect(withdrawal_amounts.annual_cash_cushion).to eq(18_000)
      end
    end
  end

  context "when user is taking OAS and is at or over the OAS start age" do
    before do
      app_config.data["oas"] = { "start_age" => 65, "years_in_canada_after_18" => 40 }
      withdrawal_amounts.current_age = 65
    end

    # OAS annual gross: (40/40.0) * 742.31 * 1.0 * 12 = 8_907.72
    # 8_907.72 is within the basic personal exemption so net OAS = 8_907.72 (zero tax)
    # RRSP: binary search finds amount where take_home(rrsp + 8_907.72) = 30_010
    #   lower bound = 33_704.73 - 8_907.72 = 24_797.01
    #   take_home(24_797.01 + 8_907.72) = take_home(33_704.73) = 30_010 ✓
    describe "#annual_rrsp" do
      it "adjusts RRSP withdrawals to account for OAS and income taxes" do
        expect(withdrawal_amounts.annual_rrsp).to be_within(2.0).of(24_797.01)
      end
    end

    describe "#annual_taxable" do
      it "reduces taxable withdrawals by net OAS income" do
        # 30_010 - 8_907.72 = 21_102.28
        expect(withdrawal_amounts.annual_taxable).to be_within(0.01).of(21_102.28)
      end
    end

    describe "#annual_tfsa" do
      it "reduces TFSA withdrawals by net OAS income" do
        # 30_000 - 8_907.72 = 21_092.28
        expect(withdrawal_amounts.annual_tfsa).to be_within(0.01).of(21_092.28)
      end
    end

    describe "#annual_cash_cushion" do
      it "reduces cash cushion withdrawals by net OAS income" do
        expect(withdrawal_amounts.annual_cash_cushion).to be_within(0.01).of(21_092.28)
      end
    end
  end

  context "when user is taking OAS but is under the OAS start age" do
    before do
      app_config.data["oas"] = { "start_age" => 65, "years_in_canada_after_18" => 40 }
      withdrawal_amounts.current_age = 64
    end

    describe "#annual_rrsp" do
      it "returns the RRSP amount as if there were no OAS" do
        expect(withdrawal_amounts.annual_rrsp).to eq(33_704.73)
      end
    end

    describe "#annual_taxable" do
      it "returns desired spending plus TFSA contribution" do
        expect(withdrawal_amounts.annual_taxable).to eq(30_010)
      end
    end

    describe "#annual_tfsa" do
      it "returns the desired spending amount" do
        expect(withdrawal_amounts.annual_tfsa).to eq(30_000)
      end
    end
  end

  context "when user is taking both CPP and OAS" do
    before do
      app_config.cpp["monthly_amount"] = 1_000
      app_config.data["oas"] = { "start_age" => 65, "years_in_canada_after_18" => 40 }
      withdrawal_amounts.current_age = 65
    end

    # cpp_gross = 12_000, oas_gross = 8_907.72
    # lower bound = 33_704.73 - 12_000 - 8_907.72 = 12_797.01
    # take_home(12_797.01 + 12_000 + 8_907.72) = take_home(33_704.73) = 30_010 ✓
    describe "#annual_rrsp" do
      it "adjusts RRSP withdrawals to account for both CPP and OAS income taxes" do
        expect(withdrawal_amounts.annual_rrsp).to be_within(2.0).of(12_797.01)
      end
    end

    describe "#annual_taxable" do
      it "reduces taxable withdrawals by net CPP and net OAS income" do
        # 30_010 - 12_000 - 8_907.72 = 9_102.28
        expect(withdrawal_amounts.annual_taxable).to be_within(0.01).of(9_102.28)
      end
    end

    describe "#annual_tfsa" do
      it "reduces TFSA withdrawals by net CPP and net OAS income" do
        # 30_000 - 12_000 - 8_907.72 = 9_092.28
        expect(withdrawal_amounts.annual_tfsa).to be_within(0.01).of(9_092.28)
      end
    end
  end

  context "when user is taking OAS and has crossed age 75" do
    before do
      app_config.data["oas"] = { "start_age" => 65, "years_in_canada_after_18" => 40 }
      withdrawal_amounts.current_age = 75
    end

    # OAS switches to ages_75_plus rate: (40/40.0) * 816.54 * 1.0 * 12 = 9_798.48
    # Still within basic personal exemption so net = gross
    describe "#annual_rrsp" do
      it "uses the enhanced 75+ OAS rate in the binary search" do
        # lower bound = 33_704.73 - 9_798.48 = 23_906.25
        expect(withdrawal_amounts.annual_rrsp).to be_within(2.0).of(23_906.25)
      end
    end

    describe "#annual_tfsa" do
      it "reduces TFSA withdrawals using the enhanced 75+ OAS rate" do
        # 30_000 - 9_798.48 = 20_201.52
        expect(withdrawal_amounts.annual_tfsa).to be_within(0.01).of(20_201.52)
      end
    end
  end

  context "when user has an annuity active (no CPP, no OAS)" do
    before do
      app_config.data["annuity"] = { "purchase_age" => 65, "lump_sum" => 200_000, "monthly_payment" => 1_000 }
      withdrawal_amounts.annuity_active = true
      withdrawal_amounts.current_age = 65
    end

    # annuity_gross = 1_000 * 12 = 12_000
    # 12_000 is within the basic personal credit so net annuity = 12_000 (zero tax)
    # lower bound = 33_704.73 - 12_000 = 21_704.73
    # take_home(21_704.73 + 12_000) = take_home(33_704.73) = 30_010 ✓
    describe "#annuity_used?" do
      it "returns true" do
        expect(withdrawal_amounts.annuity_used?).to be(true)
      end
    end

    describe "#annuity_annual_gross_income" do
      it "returns monthly_payment * 12" do
        expect(withdrawal_amounts.annuity_annual_gross_income).to eq(12_000)
      end
    end

    describe "#annual_rrsp" do
      it "adjusts RRSP withdrawals to account for annuity income and taxes" do
        expect(withdrawal_amounts.annual_rrsp).to be_within(2.0).of(21_704.73)
      end
    end

    describe "#annual_taxable" do
      it "reduces taxable withdrawals by net annuity income" do
        # 30_010 - 12_000 = 18_010
        expect(withdrawal_amounts.annual_taxable).to eq(18_010)
      end
    end

    describe "#annual_tfsa" do
      it "reduces TFSA withdrawals by net annuity income" do
        # 30_000 - 12_000 = 18_000
        expect(withdrawal_amounts.annual_tfsa).to eq(18_000)
      end
    end

    describe "#annual_cash_cushion" do
      it "reduces cash cushion withdrawals by net annuity income" do
        expect(withdrawal_amounts.annual_cash_cushion).to eq(18_000)
      end
    end
  end

  context "when user has annuity and CPP (no OAS)" do
    before do
      app_config.cpp["monthly_amount"] = 1_000
      app_config.data["annuity"] = { "purchase_age" => 65, "lump_sum" => 200_000, "monthly_payment" => 500 }
      withdrawal_amounts.annuity_active = true
      withdrawal_amounts.current_age = 65
    end

    # cpp_gross = 12_000, annuity_gross = 6_000
    # lower bound = 33_704.73 - 12_000 - 6_000 = 15_704.73
    describe "#annual_rrsp" do
      it "adjusts RRSP withdrawals to account for both CPP and annuity" do
        expect(withdrawal_amounts.annual_rrsp).to be_within(2.0).of(15_704.73)
      end
    end

    describe "#annual_taxable" do
      it "reduces taxable withdrawals by net CPP and annuity income" do
        # 30_010 - 12_000 - 6_000 = 12_010
        expect(withdrawal_amounts.annual_taxable).to eq(12_010)
      end
    end
  end

  context "when user has annuity, CPP, and OAS (all three)" do
    before do
      app_config.cpp["monthly_amount"] = 1_000
      app_config.data["oas"] = { "start_age" => 65, "years_in_canada_after_18" => 40 }
      app_config.data["annuity"] = { "purchase_age" => 65, "lump_sum" => 200_000, "monthly_payment" => 500 }
      withdrawal_amounts.annuity_active = true
      withdrawal_amounts.current_age = 65
    end

    # cpp_gross = 12_000, oas_gross = 8_907.72, annuity_gross = 6_000
    # lower bound = 33_704.73 - 12_000 - 8_907.72 - 6_000 = 6_797.01
    describe "#annual_rrsp" do
      it "adjusts RRSP withdrawals to account for CPP, OAS, and annuity" do
        expect(withdrawal_amounts.annual_rrsp).to be_within(2.0).of(6_797.01)
      end
    end

    describe "#annual_taxable" do
      it "reduces taxable withdrawals by all three net incomes" do
        # 30_010 - 12_000 - 8_907.72 - 6_000 = 3_102.28
        expect(withdrawal_amounts.annual_taxable).to be_within(0.01).of(3_102.28)
      end
    end
  end

  context "when annuity is not yet active (current_age < purchase_age)" do
    before do
      app_config.data["annuity"] = { "purchase_age" => 70, "lump_sum" => 200_000, "monthly_payment" => 1_000 }
      withdrawal_amounts.annuity_active = true
      withdrawal_amounts.current_age = 65
    end

    describe "#annuity_used?" do
      it "returns false" do
        expect(withdrawal_amounts.annuity_used?).to be(false)
      end
    end

    describe "#annual_rrsp" do
      it "returns the RRSP amount as if there were no annuity" do
        expect(withdrawal_amounts.annual_rrsp).to eq(33_704.73)
      end
    end

    describe "#annual_taxable" do
      it "returns desired spending plus TFSA contribution" do
        expect(withdrawal_amounts.annual_taxable).to eq(30_010)
      end
    end
  end

  context "when no annuity section in config" do
    before { withdrawal_amounts.current_age = 65 }

    describe "#annuity_used?" do
      it "returns false" do
        expect(withdrawal_amounts.annuity_used?).to be(false)
      end
    end
  end

  context "when annuity is configured but annuity_active is false (purchase was skipped)" do
    before do
      app_config.data["annuity"] = { "purchase_age" => 65, "lump_sum" => 200_000, "monthly_payment" => 1_000 }
      withdrawal_amounts.current_age = 65
    end

    describe "#annuity_used?" do
      it "returns false" do
        expect(withdrawal_amounts.annuity_used?).to be(false)
      end
    end

    describe "#annual_rrsp" do
      it "returns the RRSP amount as if there were no annuity" do
        expect(withdrawal_amounts.annual_rrsp).to eq(33_704.73)
      end
    end

    describe "#annual_taxable" do
      it "returns desired spending plus TFSA contribution" do
        expect(withdrawal_amounts.annual_taxable).to eq(30_010)
      end
    end

    describe "#annual_tfsa" do
      it "returns the desired spending amount" do
        expect(withdrawal_amounts.annual_tfsa).to eq(30_000)
      end
    end

    describe "#annual_cash_cushion" do
      it "returns the desired spending amount" do
        expect(withdrawal_amounts.annual_cash_cushion).to eq(30_000)
      end
    end
  end

  context "when annuity has monthly_payment of 0" do
    before do
      app_config.data["annuity"] = { "purchase_age" => 65, "lump_sum" => 200_000, "monthly_payment" => 0 }
      withdrawal_amounts.current_age = 65
    end

    describe "#annuity_used?" do
      it "returns false" do
        expect(withdrawal_amounts.annuity_used?).to be(false)
      end
    end
  end

  context "when user is taking CPP but is under the CPP start age" do
    before do
      app_config.cpp["monthly_amount"] = 1_000
      withdrawal_amounts.current_age = 64
    end

    describe "#annual_rrsp" do
      it "returns the RRSP withdrawal amount needed to meet spending needs accounting for income taxes" do
        expect(withdrawal_amounts.annual_rrsp).to eq(33_704.73)
      end
    end

    describe "#annual_taxable" do
      it "returns desired spending plus TFSA contribution" do
        expect(withdrawal_amounts.annual_taxable).to eq(30_010)
      end
    end

    describe "#annual_tfsa" do
      it "returns the desired spending amount" do
        expect(withdrawal_amounts.annual_tfsa).to eq(30_000)
      end
    end

    describe "#annual_cash_cushion" do
      it "returns the desired spending amount" do
        expect(withdrawal_amounts.annual_cash_cushion).to eq(30_000)
      end
    end
  end
end

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

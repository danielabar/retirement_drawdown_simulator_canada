# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe Strategy::WithdrawalPlanner do
  subject(:withdrawal_planner) do
    described_class.new(withdrawal_amounts, rrsp_account, taxable_account, tfsa_account, "ONT")
  end

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
        "savings" => 0.005,
        "downturn_threshold" => -0.1
      },
      "accounts" => {
        "rrsp" => 200_000,
        "taxable" => 60_000,
        "tfsa" => 30_000,
        "cash_cushion" => 30_000
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
  let(:withdrawal_amounts) { WithdrawalAmounts.new(app_config) }
  let(:rrsp_account) { Account.new("rrsp", app_config.accounts["rrsp"]) }
  let(:taxable_account) { Account.new("taxable", app_config.accounts["taxable"]) }
  let(:tfsa_account) { Account.new("tfsa", app_config.accounts["tfsa"]) }

  describe "#plan_withdrawals" do
    context "when rrif withdrawals are required and greater than what user needs to withdraw" do
      before do
        # Set a high age for maximum forced rate of 20% (see `config/rrif_fixed.yml`)
        withdrawal_amounts.current_age = 95
      end

      it "calculates a positive forced net excess withdrawal" do
        # Given the fixed tax rates at `config/tax_fixed.yml`,
        # for Ontario and desired income of 30_010 (30_000 desired spending + 10 tfsa contribution)
        # this user only needs to withdraw 33_704.73 gross from their RRSP
        # (use Tax::ReverseIncomeTaxCalculator in a console to verify).
        # But RRIF at age 95 is 20% of the RRSP balance which is:
        # 200_000 * 0.2 = 40_000
        # Therefore they're going to be forced to withdraw 40_000 gross
        # which results in a take home of: 35_043.0735 (use Tax::IncomeTaxCalculator in a console to verify)
        # Since they only needed 30_010 of this, they'll be left with a forced net excess of:
        # 35_043.0735 - 30_010 = 5_033.0735
        account_transactions = withdrawal_planner.plan_withdrawals
        expect(account_transactions).to contain_exactly(a_hash_including(
                                                          account: rrsp_account,
                                                          amount: a_value_within(0.01).of(40_000),
                                                          forced_net_excess: a_value_within(0.01).of(5_033.07)
                                                        ))
      end
    end

    context "when rrif withdrawals are required and less than what user needs to withdraw" do
      before do
        # Set a low age for a forced rate of just over 5% (see `config/rrif_fixed.yml`)
        withdrawal_amounts.current_age = 71
      end

      it "calculates zero for forced net excess withdrawal" do
        # Given the fixed tax rates at `config/tax_fixed.yml`,
        # for Ontario and desired income of 30_010 (30_000 desired spending + 10 tfsa contribution)
        # this user only needs to withdraw 33_704.73 gross from their RRSP
        # (use Tax::ReverseIncomeTaxCalculator in a console to verify).
        # The RRIF at age 71 is 5.28% of the RRSP balance which is:
        # 200_000 * 0.0528 = 10,560
        # This is less than what the user was going to withdraw in any case so the forced_net_excess will be 0.
        account_transactions = withdrawal_planner.plan_withdrawals
        expect(account_transactions).to contain_exactly(a_hash_including(
                                                          account: rrsp_account,
                                                          amount: a_value_within(0.01).of(33_704.73),
                                                          forced_net_excess: 0
                                                        ))
      end
    end
  end

  describe "#mandatory_rrif_withdrawal" do
    it "returns rrif amount for age 71" do
      withdrawal_amounts.current_age = 71
      expect(withdrawal_planner.mandatory_rrif_withdrawal).to eq(10_560)
    end

    it "returns 0 for age less than 71" do
      withdrawal_amounts.current_age = 70
      expect(withdrawal_planner.mandatory_rrif_withdrawal).to eq(0)
    end
  end
end

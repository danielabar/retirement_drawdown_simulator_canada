# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe Strategy::RrspToTaxableToTfsa do
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
        "rrsp" => 80_000,
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

  let(:strategy) { described_class.new(app_config) }

  before do
    strategy.current_age = 65
  end

  describe "#select_account_transactions" do
    context "when market return is below downturn threshold and cash cushion has enough funds" do
      it "selects the cash cushion account with desired spending amount" do
        expect(strategy.select_account_transactions(-0.15)).to include(account: strategy.cash_cushion, amount: 30_000)
      end
    end

    context "when market return is below downturn threshold and cash cushion does not have enough funds" do
      before { strategy.cash_cushion.withdraw(30_000) } # Empty Cash Cushion

      it "selects the rrsp account with gross withdrawal amount if it has sufficient balance" do
        expect(strategy.select_account_transactions(-0.15)).to include(account: strategy.rrsp_account,
                                                                       amount: 33_704.73, forced_net_excess: 0)
      end
    end

    context "when RRSP has enough balance" do
      it "selects the RRSP account with gross withdrawal amount" do
        expect(strategy.select_account_transactions(0.05)).to include(account: strategy.rrsp_account,
                                                                      amount: 33_704.73, forced_net_excess: 0)
      end
    end

    context "when RRSP has nothing but taxable has enough balance" do
      before { strategy.rrsp_account.withdraw(80_000) } # Empty RRSP

      it "selects the taxable account with desired spending amount plus tfsa contribution" do
        expect(strategy.select_account_transactions(0.05)).to include(account: strategy.taxable_account, amount: 30_010)
      end
    end

    context "when RRSP and taxable have nothing, but TFSA has enough balance" do
      before do
        strategy.rrsp_account.withdraw(80_000) # Empty RRSP
        strategy.taxable_account.withdraw(60_000) # Empty taxable
      end

      it "selects the TFSA account with desired spending amount" do
        expect(strategy.select_account_transactions(0.05)).to include(account: strategy.tfsa_account, amount: 30_000)
      end
    end

    context "when RRSP has some funds but not enough for full gross withdrawal" do
      before do
        # there's still 20_000 left - not enough for full withdrawal of 33_704.73
        # but it is enough to trigger income tax which complicates remaining needed funds
        strategy.rrsp_account.withdraw(60_000)
      end

      # 20_000 gross from RRSP in Ontario results in take_home of 19053.0735 (based on config/tax_fixed.yml)
      # The amount otherwise that we would want from taxable is defined in withdrawal amounts `annual_taxable`:
      # desired_spending + annual_tfsa_contribution = 30_000 + 10 = 30_010` (in absence of CPP)
      # So we subtract off our take_home from RRSP from this amount to get the actual amount needed from taxable:
      # 30_010 - 19053.0735 = 10_956.9265
      it "selects the RRSP account with a partial amount and the taxable account with the remainder" do
        expect(strategy.select_account_transactions(0.05))
          .to contain_exactly(a_hash_including(
                                account: strategy.rrsp_account,
                                amount: 20_000
                              ),
                              a_hash_including(
                                account: strategy.taxable_account,
                                amount: a_value_within(0.01).of(10_956.92)
                              ))
      end
    end

    context "when RRSP has nothing and taxable have some funds but not enough for full withdrawal" do
      before do
        strategy.rrsp_account.withdraw(80_000) # Empty RRSP
        strategy.taxable_account.withdraw(50_000) # Reduce taxable so there's only 10_000 left
      end

      it "selects the taxable account with a partial amount and the TFSA account with the remainder" do
        # In this case the withdrawal amount across the two accounts does NOT include the optional TFSA contribution
        # because that doesn't make sense if withdrawing from a TFSA account.
        expect(strategy.select_account_transactions(0.05))
          .to contain_exactly(a_hash_including(
                                account: strategy.taxable_account,
                                amount: 10_000
                              ),
                              a_hash_including(
                                account: strategy.tfsa_account,
                                amount: 20_000
                              ))
      end
    end

    context "when RRSP, taxable, and TFSA have enough all together" do
      before do
        strategy.rrsp_account.withdraw(70_000) # 10K left in RRSP
        strategy.taxable_account.withdraw(50_000) # 10K left in taxable
        strategy.tfsa_account.withdraw(15_000) # 15K left in tfsa
      end

      it "selects rrsp, taxable, and tfsa accounts if together they have enough funds" do
        # In this case, the RRSP withdrawal isn't enough to trigger income tax (based on `config/tax_fixed.yml`)
        # So when calculating remaining amounts for the other accounts, it's based on after-tax amounts because
        # those accounts don't count as income the way an RRSP does.
        # Also since we're withdrawing from TFSA, will not be making the optional TFSA contribution.
        # So we're withdrawing exactly desired spending in this case of 30_000.
        expect(strategy.select_account_transactions(0.05))
          .to contain_exactly(a_hash_including(
                                account: strategy.rrsp_account,
                                amount: 10_000
                              ),
                              a_hash_including(
                                account: strategy.taxable_account,
                                amount: 10_000
                              ),
                              a_hash_including(
                                account: strategy.tfsa_account,
                                amount: a_value_within(0.01).of(10_000)
                              ))
      end
    end

    context "when there is some but not enough fund across all investment accounts" do
      before do
        strategy.rrsp_account.withdraw(75_000) # 5K left in RRSP
        strategy.taxable_account.withdraw(50_000) # 10K left in taxable
        strategy.tfsa_account.withdraw(20_000) # 10K left in tfsa
      end

      it "returns an empty array" do
        expect(strategy.select_account_transactions(0.05)).to eq([])
      end
    end

    context "when rrsp doesn't have enough including tfsa contribution and other accounts don't have enough" do
      # need rrsp to be down to 33_692.22 (just enough for after-tax desired spending but not enough for tfsa contrib)
      # and need taxable and tfsa to be down to $1 so that all together not enough
      # then it will recalculate everything based on no tfsa contribution,
      # and in this case, rrsp has enough
      before do
        strategy.rrsp_account.withdraw(46_307.78)
        strategy.taxable_account.withdraw(59_999)
        strategy.tfsa_account.withdraw(29_999)
      end

      it "selects the rrsp account with gross desired spending amount" do
        expect(strategy.select_account_transactions(0.05)).to include(account: strategy.rrsp_account,
                                                                      amount: 33_692.22, forced_net_excess: 0)
      end
    end

    context "when all accounts are depleted" do
      before do
        strategy.rrsp_account.withdraw(80_000)
        strategy.taxable_account.withdraw(60_000)
        strategy.tfsa_account.withdraw(30_000)
        strategy.cash_cushion.withdraw(10_000)
      end

      it "returns an empty array" do
        expect(strategy.select_account_transactions(0.05)).to eq([])
      end
    end
  end

  describe "#transact" do
    it "processes withdrawals from rrsp and taxable and makes a tfsa contribution" do
      account_transactions = [
        { account: strategy.rrsp_account, amount: 5_000 },
        { account: strategy.taxable_account, amount: 10_000 }
      ]
      strategy.transact(account_transactions)

      expect(strategy.rrsp_account.balance).to eq(75_000)
      expect(strategy.taxable_account.balance).to eq(50_000)
      expect(strategy.tfsa_account.balance).to eq(30_010)
    end

    it "processes withdrawals from rrsp, taxable and tfsa, and does not make a tfsa contribution" do
      account_transactions = [
        { account: strategy.rrsp_account, amount: 5_000 },
        { account: strategy.taxable_account, amount: 10_000 },
        { account: strategy.tfsa_account, amount: 15_000 }
      ]
      strategy.transact(account_transactions)

      expect(strategy.rrsp_account.balance).to eq(75_000)
      expect(strategy.taxable_account.balance).to eq(50_000)
      expect(strategy.tfsa_account.balance).to eq(15_000)
    end

    it "processes withdrawal from cash cushion and does not make a tfsa contribution" do
      account_transactions = [
        { account: strategy.cash_cushion, amount: 10_000 }
      ]
      strategy.transact(account_transactions)

      expect(strategy.cash_cushion.balance).to eq(20_000)
    end

    it "processes withdrawal from rrsp and makes a deposit to taxable account if there is a RRIF forced excess" do
      account_transactions = [
        { account: strategy.rrsp_account, amount: 5_000, forced_net_excess: 1_000 }
      ]
      strategy.transact(account_transactions)

      # rrsp account balance goes down by 5_000
      expect(strategy.rrsp_account.balance).to eq(75_000)

      # taxable account balance goes up by 1_000 due RRIF forced excess
      expect(strategy.taxable_account.balance).to eq(61_000)

      # still making a tfsa contribution
      expect(strategy.tfsa_account.balance).to eq(30_010)
    end
  end

  describe "#total_balance" do
    it "includes the cash cushion balance in the total balance" do
      # 80,000 (RRSP) + 60,000 (Taxable) + 30,000 (TFSA) + 30,000 (Cash Cushion)
      expect(strategy.total_balance).to eq(200_000)
    end

    context "when cash cushion balance is zero" do
      before { strategy.cash_cushion.withdraw(30_000) } # Empty cash cushion

      it "does not include the cash cushion balance when it's zero" do
        # 80,000 (RRSP) + 60,000 (Taxable) + 30,000 (TFSA)
        expect(strategy.total_balance).to eq(170_000)
      end
    end
  end
end

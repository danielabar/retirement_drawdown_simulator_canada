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

  describe "#select_accounts" do
    context "when market return is below downturn threshold and cash cushion has enough funds" do
      it "selects the cash cushion account with desired spending amount" do
        expect(strategy.select_accounts(-0.15)).to include(account: strategy.cash_cushion, amount: 30_000)
      end
    end

    context "when market return is below downturn threshold and cash cushion does not have enough funds" do
      before { strategy.cash_cushion.withdraw(30_000) } # Empty Cash Cushion

      it "selects the rrsp account with gross withdrawal amount if it has sufficient balance" do
        expect(strategy.select_accounts(-0.15)).to include(account: strategy.rrsp_account, amount: 33_704.73)
      end
    end

    context "when RRSP has enough balance" do
      it "selects the RRSP account with gross withdrawal amount" do
        expect(strategy.select_accounts(0.05)).to include(account: strategy.rrsp_account, amount: 33_704.73)
      end
    end

    context "when RRSP is insufficient but taxable has enough balance" do
      before { strategy.rrsp_account.withdraw(80_000) } # Empty RRSP

      it "selects the taxable account with desired spending amount plus tfsa contribution" do
        expect(strategy.select_accounts(0.05)).to include(account: strategy.taxable_account, amount: 30_010)
      end
    end

    context "when RRSP and taxable are insufficient, but TFSA has enough balance" do
      before do
        strategy.rrsp_account.withdraw(80_000) # Empty RRSP
        strategy.taxable_account.withdraw(60_000) # Empty taxable
      end

      it "selects the TFSA account with desired spending amount" do
        expect(strategy.select_accounts(0.05)).to include(account: strategy.tfsa_account, amount: 30_000)
      end
    end

    context "when RRSP has some funds but not enough for full gross withdrawal" do
      before do
        # there's still 10_000 left but that's not enough for full withdrawal of 33_704.73
        strategy.rrsp_account.withdraw(70_000)
      end

      it "selects the RRSP account with a partial amount and the taxable account with the remainder" do
        expect(strategy.select_accounts(0.05))
          .to contain_exactly(a_hash_including(
                                account: strategy.rrsp_account,
                                amount: 10_000
                              ),
                              a_hash_including(
                                account: strategy.taxable_account,
                                amount: a_value_within(0.01).of(23_704.73)
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
        expect(strategy.select_accounts(0.05))
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

    context "when all accounts are depleted" do
      before do
        strategy.rrsp_account.withdraw(80_000)
        strategy.taxable_account.withdraw(60_000)
        strategy.tfsa_account.withdraw(30_000)
        strategy.cash_cushion.withdraw(10_000)
      end

      it "returns an empty array" do
        expect(strategy.select_accounts(0.05)).to eq([])
      end
    end
  end

  describe "#transact" do
    context "when given RRSP account" do
      it "depletes the account by the RRSP withdrawal amount" do
        rrsp_withdrawal_amount = strategy.withdrawal_amounts.annual_rrsp
        expect { strategy.transact(strategy.rrsp_account) }
          .to change { strategy.rrsp_account.balance }.by(-rrsp_withdrawal_amount)
      end

      it "makes a TFSA deposit" do
        expect { strategy.transact(strategy.rrsp_account) }
          .to change { strategy.tfsa_account.balance }.by(10)
      end
    end

    context "when given taxable account" do
      it "depletes the account by the taxable withdrawal amount" do
        # desired_spending + annual_tfsa_contribution
        expect { strategy.transact(strategy.taxable_account) }
          .to change { strategy.taxable_account.balance }.by(-30_010)
      end

      it "makes a TFSA deposit" do
        expect { strategy.transact(strategy.taxable_account) }
          .to change { strategy.tfsa_account.balance }.by(10)
      end
    end

    context "when given TFSA account" do
      it "depletes the account by the TFSA withdrawal amount" do
        # desired_spending only
        expect { strategy.transact(strategy.tfsa_account) }
          .to change { strategy.tfsa_account.balance }.by(-30_000)
      end
    end

    context "when given cash cushion account" do
      it "depletes the account by the cash cushion withdrawal amount" do
        # desired_spending only
        expect { strategy.transact(strategy.cash_cushion) }
          .to change { strategy.cash_cushion.balance }.by(-30_000)
      end

      it "does NOT make a TFSA deposit (failing test for bug)" do
        expect { strategy.transact(strategy.cash_cushion) }
          .not_to(change { strategy.tfsa_account.balance })
      end
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

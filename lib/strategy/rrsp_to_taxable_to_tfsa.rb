# frozen_string_literal: true

module Strategy
  class RrspToTaxableToTfsa
    attr_reader :app_config, :current_age, :withdrawal_amounts, :rrsp_account, :taxable_account, :tfsa_account,
                :cash_cushion

    def initialize(app_config)
      @app_config = app_config
      @withdrawal_amounts = WithdrawalAmounts.new(app_config)
      @tax_calculator = Tax::IncomeTaxCalculator.new
      load_accounts
    end

    def current_age=(age)
      @current_age = age
      @withdrawal_amounts.current_age = age
    end

    # TODO: 27 - method naming needs more thought:
    # This isn't so much about selecting accounts, rather its constructing
    # a series of transactions that we can then pass to the `transact` method
    # FIXME: https://github.com/danielabar/retirement_drawdown_simulator_canada/issues/20
    def select_accounts(market_return)
      if withdraw_from_cash_cushion?(market_return)
        [{ account: cash_cushion, amount: withdrawal_amounts.annual_cash_cushion }]
      else
        select_investment_accounts
      end
    end

    # TODO: 27 - tests
    # TODO: 27 - rubocop complexity
    # TODO: 27 - arg should be named `transactions` rather than `accounts`
    def transact(accounts)
      return if accounts.nil? || accounts.empty?

      accounts.each do |entry|
        entry[:account].withdraw(entry[:amount])
      end

      # Ensure TFSA contributions only happen if we withdrew from RRSP/Taxable
      if accounts.none? { |entry| %w[tfsa cash_cushion].include?(entry[:account].name) } &&
         app_config["annual_tfsa_contribution"].positive?
        tfsa_account.deposit(app_config["annual_tfsa_contribution"])
      end
    end

    def apply_growth(market_return)
      [rrsp_account, taxable_account, tfsa_account, cash_cushion].each do |account|
        account.apply_growth(market_return)
      end
    end

    def total_balance
      rrsp_account.balance + taxable_account.balance + tfsa_account.balance + cash_cushion.balance
    end

    def cpp_used?
      withdrawal_amounts.cpp_used?
    end

    private

    def load_accounts
      @rrsp_account = create_account("rrsp")
      @taxable_account = create_account("taxable")
      @tfsa_account = create_account("tfsa")
      @cash_cushion = create_cash_cushion
    end

    def create_account(name)
      Account.new(name, app_config.accounts[name])
    end

    def create_cash_cushion
      Account.new("cash_cushion", app_config.accounts["cash_cushion"], app_config.annual_growth_rate["savings"])
    end

    # TODO: 27 - may no longer be used
    def select_cash_cushion(market_return)
      cash_cushion if withdraw_from_cash_cushion?(market_return)
    end

    # TODO: 27 - method naming needs more thought:
    # This isn't so much about selecting accounts, rather its constructing
    # a series of transactions that we can then pass to the `transact` method
    # TODO: 27 - rubocop complexity - maybe some intermediate calculations belong in WithdrawalAmounts
    def select_investment_accounts
      selected_accounts = []

      puts "=== SELECTING INVESTMENT ACCOUNTS FOR AGE #{current_age} ==="

      # Step 1: Determine initial withdrawal need
      remaining_needed = if rrsp_account.balance.positive?
                           withdrawal_amounts.annual_rrsp
                         else
                           withdrawal_amounts.annual_taxable
                         end

      # Step 2: Select RRSP account
      if rrsp_account.balance.positive?
        rrsp_withdrawal = [rrsp_account.balance, withdrawal_amounts.annual_rrsp].min
        selected_accounts << { account: rrsp_account, amount: rrsp_withdrawal }
        # Can't do a simple decrement on remaining_needed here because RRSP withdrawals are taxed as income,
        # and the other accounts that will be used to make up the difference are not taxed as income.
        after_tax_rrsp_amt = @tax_calculator.calculate(rrsp_withdrawal, app_config["province_code"])[:take_home]

        # Don't attempt to cascade to other accounts if RRSP withdrawal is all that's needed
        return selected_accounts if rrsp_withdrawal == withdrawal_amounts.annual_rrsp

        remaining_needed = withdrawal_amounts.annual_taxable - after_tax_rrsp_amt
        puts "=== RRSP WASN'T ENOUGH: REMAINING NEEDED IS #{remaining_needed} ==="
      end

      # Step 3: Additionally select Taxable account
      if remaining_needed.positive? && taxable_account.balance.positive?
        taxable_withdrawal = [taxable_account.balance, remaining_needed].min
        selected_accounts << { account: taxable_account, amount: taxable_withdrawal }
        remaining_needed -= taxable_withdrawal # No tax adjustment needed
        puts "=== TAXABLE WASN'T ENOUGH: REMAINING NEEDED IS #{remaining_needed} ===" if remaining_needed.positive?
      end

      # BUG: === REMAINING NEEDED: 6881.994835216643 ===
      # If remaining needed is less than optional TFSA contribution, then this code doesn't run
      # but it leaves us with a positive remaining needed and thinks its a failure
      # when really, if we have to dip into TFSA, we're just going to skip on optional TFSA contribution in any case
      # We could just return the list of transactions so far but this means we withdrew too much from taxable account
      # Need to kind of "back up" and update withdrawal amount from taxable
      # But when transact runs, it it doesn't see a TFSA account in list of transactions, it's going to go ahead and make TFSA contribution
      # which it should not do in this case
      # Or should we give up on the idea of making optional TFSA contributions entirely, more complexity than it's worth?
      # Missing a test for this case!
      #
      # Step 4: Additionally select TFSA account
      # If we get here, we should not be including tfsa_contribution in the withdrawal amount
      # that may have been there from original `remaining_needed` but that only makes sense when
      # withdrawing from rrsp or taxable account.
      if (remaining_needed - app_config["annual_tfsa_contribution"]).positive? && tfsa_account.balance.positive?
        remaining_needed -= app_config["annual_tfsa_contribution"]
        tfsa_withdrawal = [tfsa_account.balance, remaining_needed].min
        selected_accounts << { account: tfsa_account, amount: tfsa_withdrawal }
        remaining_needed -= tfsa_withdrawal
        puts "=== TFSA WASN'T ENOUGH: REMAINING NEEDED IS #{remaining_needed} ===" if remaining_needed.positive?
      end

      # If we still need more money and there's no way to cover it, return an empty array
      # TODO: Future bugfix - should consider cash cushion as a last resort
      puts "=== REMAINING NEEDED: #{remaining_needed} ==="
      puts " "
      return [] if remaining_needed.positive?

      selected_accounts
    end

    def withdraw_from_cash_cushion?(market_return)
      market_return < app_config.annual_growth_rate["downturn_threshold"] &&
        cash_cushion.balance >= withdrawal_amounts.annual_cash_cushion
    end

    # TODO: 27 - may no longer be used and can be removed
    # We can't simply compare to `desired_spending` because withdrawals from
    # RRSP count as income and are taxed, thus requiring a larger withdrawal.
    def sufficient_balance?(account)
      balance_needed = withdrawal_amounts.public_send("annual_#{account.name}")
      account.balance >= balance_needed
    end
  end
end

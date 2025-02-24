# frozen_string_literal: true

module Strategy
  class RrspToTaxableToTfsa
    attr_reader :app_config, :current_age, :withdrawal_amounts, :rrsp_account, :taxable_account, :tfsa_account,
                :cash_cushion

    def initialize(app_config)
      @app_config = app_config
      @withdrawal_amounts = WithdrawalAmounts.new(app_config)
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
    # TODO: 27 - rubocop complexity
    def select_investment_accounts
      selected_accounts = []

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
        remaining_needed -= rrsp_withdrawal
      end

      # Step 3: Additionally select Taxable account
      if remaining_needed.positive? && taxable_account.balance.positive?
        taxable_withdrawal = [taxable_account.balance, remaining_needed].min
        selected_accounts << { account: taxable_account, amount: taxable_withdrawal }
        remaining_needed -= taxable_withdrawal # No tax adjustment needed
      end

      # Step 4: Additionally select TFSA account
      # If we get here, we should not be including tfsa_contribution in the withdrawal amount
      # that may have been there from original `remaining_needed` but that only makes sense when
      # withdrawing from rrsp or taxable account.
      if (remaining_needed - app_config["annual_tfsa_contribution"]).positive? && tfsa_account.balance.positive?
        remaining_needed -= app_config["annual_tfsa_contribution"]
        tfsa_withdrawal = [tfsa_account.balance, remaining_needed].min
        selected_accounts << { account: tfsa_account, amount: tfsa_withdrawal }
        remaining_needed -= tfsa_withdrawal
      end

      # If we still need more money and there's no way to cover it, return an empty array
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

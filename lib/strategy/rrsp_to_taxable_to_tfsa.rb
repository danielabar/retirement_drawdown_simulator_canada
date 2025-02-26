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
        WithdrawalPlanner.new(withdrawal_amounts, rrsp_account, taxable_account, tfsa_account,
                              app_config["province_code"]).plan_withdrawals
      end
    end

    # TODO: 27 - arg should be named `account_transactions` rather than `accounts`
    def transact(accounts)
      return if ran_out_of_money?(accounts)

      accounts.each do |entry|
        entry[:account].withdraw(entry[:amount])
      end

      # Ensure TFSA deposits only happen if we withdrew from RRSP/Taxable
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

    def ran_out_of_money?(account_transactions)
      account_transactions.nil? || account_transactions.empty?
    end

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

    def withdraw_from_cash_cushion?(market_return)
      market_return < app_config.annual_growth_rate["downturn_threshold"] &&
        cash_cushion.balance >= withdrawal_amounts.annual_cash_cushion
    end
  end
end

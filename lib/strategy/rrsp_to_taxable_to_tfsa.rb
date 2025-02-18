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

    def select_account(market_return)
      select_cash_cushion(market_return) || select_investment_account
    end

    def transact(current_account)
      current_account.withdraw(withdrawal_amounts.annual_amount(current_account))

      # Ensure we do not contribute to TFSA if withdrawing from TFSA or cash cushion
      return unless !%w[tfsa
                        cash_cushion].include?(current_account.name) && app_config["annual_tfsa_contribution"].positive?

      tfsa_account.deposit(app_config["annual_tfsa_contribution"])
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

    def select_cash_cushion(market_return)
      cash_cushion if withdraw_from_cash_cushion?(market_return)
    end

    def select_investment_account
      [rrsp_account, taxable_account, tfsa_account].find { |account| sufficient_balance?(account) }
    end

    def withdraw_from_cash_cushion?(market_return)
      market_return < app_config.annual_growth_rate["downturn_threshold"] &&
        cash_cushion.balance >= withdrawal_amounts.annual_cash_cushion
    end

    def sufficient_balance?(account)
      balance_needed = withdrawal_amounts.public_send("annual_#{account.name}")
      account.balance >= balance_needed
    end
  end
end

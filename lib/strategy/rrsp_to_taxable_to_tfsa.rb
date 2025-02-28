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

    def select_account_transactions(market_return)
      withdrawal_planner = WithdrawalPlanner.new(withdrawal_amounts, rrsp_account, taxable_account, tfsa_account,
                                                 app_config["province_code"])

      if withdraw_from_cash_cushion?(withdrawal_planner, market_return)
        [{ account: cash_cushion, amount: withdrawal_amounts.annual_cash_cushion }]
      else
        withdrawal_planner.plan_withdrawals
      end
    end

    def transact(account_transactions)
      return if ran_out_of_money?(account_transactions)

      process_withdrawals(account_transactions)
      handle_tfsa_contribution(account_transactions)
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

    # TODO: 26 - test scenario where we would have wanted to use cash cushion
    # and not sell investments during a severe downturn,
    # but instead we're forced to withdraw from rrsp due to mandatory rrif
    def withdraw_from_cash_cushion?(withdrawal_planner, market_return)
      return false if withdrawal_planner.mandatory_rrif_withdrawal.positive?

      market_return < app_config.annual_growth_rate["downturn_threshold"] &&
        cash_cushion.balance >= withdrawal_amounts.annual_cash_cushion
    end

    def process_withdrawals(account_transactions)
      account_transactions.each do |entry|
        entry[:account].withdraw(entry[:amount])
        deposit_forced_net_excess(entry)
      end
    end

    def deposit_forced_net_excess(entry)
      return unless entry[:forced_net_excess]&.positive?

      taxable_account.deposit(entry[:forced_net_excess])
    end

    def handle_tfsa_contribution(account_transactions)
      return unless should_contribute_to_tfsa?(account_transactions)

      tfsa_account.deposit(app_config["annual_tfsa_contribution"])
    end

    def should_contribute_to_tfsa?(account_transactions)
      return false unless app_config["annual_tfsa_contribution"].positive?

      account_transactions.none? { |entry| %w[tfsa cash_cushion].include?(entry[:account].name) }
    end
  end
end

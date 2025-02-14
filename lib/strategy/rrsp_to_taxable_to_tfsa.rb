# frozen_string_literal: true

module Strategy
  class RrspToTaxableToTfsa
    attr_reader :app_config, :withdrawal_amounts, :rrsp_account, :taxable_account, :tfsa_account, :cash_cushion

    def initialize(app_config)
      @app_config = app_config
      @withdrawal_amounts = WithdrawalAmounts.new(app_config)
      load_accounts
    end

    # Interesting side effect:
    # Because we're not handling partial withdrawals (mixed from two accounts),
    # there's always a little left in any given account, and as growth is applied,
    # the following year, this logic may choose to withdraw from it again even though it was nearly depleted before.
    # TODO: Reduce the complexity of this method re: Rubocop Metrics/AbcSize
    def select_account(market_return)
      if market_return < app_config.annual_growth_rate["downturn_threshold"] &&
         @cash_cushion.balance >= withdrawal_amounts.annual_cash_cushion
        return @cash_cushion
      end

      return @rrsp_account if @rrsp_account.balance >= withdrawal_amounts.annual_rrsp
      return @taxable_account if @taxable_account.balance >= withdrawal_amounts.annual_taxable
      return @tfsa_account if @tfsa_account.balance >= withdrawal_amounts.annual_tfsa

      nil # Indicate that funds have run out
    end

    def transact(current_account)
      current_account.withdraw(withdrawal_amounts.annual_amount(current_account))
      tfsa_account.deposit(app_config["annual_tfsa_contribution"]) if app_config["annual_tfsa_contribution"].positive?
    end

    # TODO: Debatable whether this belongs here in strategy or in Simulation::Simulator
    def apply_growth(market_return)
      [rrsp_account, taxable_account, tfsa_account, cash_cushion].each do |account|
        account.apply_growth(market_return)
      end
    end

    def total_balance
      rrsp_account.balance + taxable_account.balance + tfsa_account.balance
    end

    private

    # TODO: Maybe AppConfig should be responsible for loading accounts as this info is needed throughout app.
    def load_accounts
      @rrsp_account = Account.new("rrsp", app_config.accounts["rrsp"])
      @taxable_account = Account.new("taxable", app_config.accounts["taxable"])
      @tfsa_account = Account.new("tfsa", app_config.accounts["tfsa"])
      @cash_cushion = Account.new("cash_cushion", app_config.accounts["cash_cushion"],
                                  app_config.annual_growth_rate["savings"])
    end
  end
end

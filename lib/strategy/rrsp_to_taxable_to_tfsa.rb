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

    # TODO: 27 - arg should be named `transactions` rather than `accounts`
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

    def select_investment_accounts
      selected_accounts, remaining_needed = attempt_withdrawals(exclude_tfsa_contribution: false)

      # If we need to dip into TFSA, retry excluding TFSA contribution
      if selected_accounts.any? { |entry| entry[:account] == tfsa_account }
        selected_accounts, remaining_needed = attempt_withdrawals(exclude_tfsa_contribution: true)
      end

      # If we still need more funds after trying all accounts, we ran out of money :(
      remaining_needed.positive? ? [] : selected_accounts
    end

    def attempt_withdrawals(exclude_tfsa_contribution:)
      selected_accounts = []
      remaining_needed = withdraw_from_rrsp(selected_accounts, exclude_tfsa_contribution)

      # If RRSP covered everything, no need to check taxable or TFSA
      return [selected_accounts, remaining_needed] if remaining_needed.zero?

      selected_accounts, remaining_needed = withdraw_from_taxable(selected_accounts, remaining_needed)
      selected_accounts, remaining_needed = withdraw_from_tfsa(selected_accounts, remaining_needed)

      [selected_accounts, remaining_needed]
    end

    def withdraw_from_rrsp(selected_accounts, exclude_tfsa_contribution)
      gross_withdrawal = withdrawal_amounts.annual_rrsp(exclude_tfsa_contribution: exclude_tfsa_contribution)

      if rrsp_has_sufficient_funds?(gross_withdrawal)
        withdraw_full_gross_from_rrsp(selected_accounts, gross_withdrawal)
        return 0
      elsif rrsp_has_partial_funds?
        return drain_rrsp(selected_accounts, exclude_tfsa_contribution)
      end

      # If we get here, it means RRSP is empty, so return the entire amount needed from taxable account
      withdrawal_amounts.annual_taxable(exclude_tfsa_contribution: exclude_tfsa_contribution)
    end

    def rrsp_has_sufficient_funds?(gross_withdrawal)
      rrsp_account.balance >= gross_withdrawal
    end

    def rrsp_has_partial_funds?
      rrsp_account.balance.positive?
    end

    def withdraw_full_gross_from_rrsp(selected_accounts, gross_withdrawal)
      selected_accounts << { account: rrsp_account, amount: gross_withdrawal }
    end

    def drain_rrsp(selected_accounts, exclude_tfsa_contribution)
      selected_accounts << { account: rrsp_account, amount: rrsp_account.balance }
      after_tax = after_tax_withdrawal(rrsp_account.balance)
      withdrawal_amounts.annual_taxable(exclude_tfsa_contribution: exclude_tfsa_contribution) - after_tax
    end

    def withdraw_from_taxable(selected_accounts, remaining_needed)
      return [selected_accounts, remaining_needed] if remaining_needed <= 0 || taxable_account.balance.zero?

      taxable_withdrawal = [taxable_account.balance, remaining_needed].min
      selected_accounts << { account: taxable_account, amount: taxable_withdrawal }
      remaining_needed -= taxable_withdrawal

      [selected_accounts, remaining_needed]
    end

    def withdraw_from_tfsa(selected_accounts, remaining_needed)
      return [selected_accounts, remaining_needed] if remaining_needed <= 0 || tfsa_account.balance.zero?

      tfsa_withdrawal = [tfsa_account.balance, remaining_needed].min
      selected_accounts << { account: tfsa_account, amount: tfsa_withdrawal }
      remaining_needed -= tfsa_withdrawal

      [selected_accounts, remaining_needed]
    end

    def after_tax_withdrawal(amount)
      @tax_calculator.calculate(amount, app_config["province_code"])[:take_home]
    end

    def withdraw_from_cash_cushion?(market_return)
      market_return < app_config.annual_growth_rate["downturn_threshold"] &&
        cash_cushion.balance >= withdrawal_amounts.annual_cash_cushion
    end
  end
end

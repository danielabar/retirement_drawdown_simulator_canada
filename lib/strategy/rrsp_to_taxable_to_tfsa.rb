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
      remaining_needed = 0

      # Simplest case: RRSP has enough for everything, we're done
      rrsp_withdrawal = withdrawal_amounts.annual_rrsp
      if rrsp_account.balance >= rrsp_withdrawal
        selected_accounts << { account: rrsp_account, amount: rrsp_withdrawal }
        # puts "=== RRSP HAS ENOUGH FOR EVERYTHING ==="
        return selected_accounts
      end

      # Otherwise drain what's left (if there's more than zero) and calculate how much more is needed after-tax
      if rrsp_account.balance.positive? && rrsp_account.balance < rrsp_withdrawal
        selected_accounts << { account: rrsp_account, amount: rrsp_account.balance }
        after_tax_rrsp_amt = @tax_calculator.calculate(rrsp_account.balance, app_config["province_code"])[:take_home]
        remaining_needed = withdrawal_amounts.annual_taxable - after_tax_rrsp_amt
        # puts "=== WITHDRAWING PARTIAL FROM RRSP: #{NumericFormatter.format_currency(rrsp_account.balance)}, REMAINING NEEDED: #{NumericFormatter.format_currency(remaining_needed)} ==="
      end

      # If there's nothing left in RRSP, then we need to lean on the next account for the whole thing
      remaining_needed = withdrawal_amounts.annual_taxable if rrsp_account.balance.zero?

      # If taxable account has remaining_needed, add it to selected_accounts and we're done
      if taxable_account.balance.positive? && taxable_account.balance >= remaining_needed
        selected_accounts << { account: taxable_account, amount: remaining_needed }
        # puts "=== WITHDRAWING FROM TAXABLE: #{NumericFormatter.format_currency(remaining_needed)} ==="
        return selected_accounts
      end

      # TODO: 27 - If annual_tfsa_contribution was 0, then effectively above calculations were without TFSA contribution
      # and no need to recalculate, just try to dip into TFSA and see if that works. Although it does no harm to recalculate.
      # If we get here, it means rrsp and/or taxable accounts don't have enough and we need to dip into TFSA.
      # In this case, we will not be making a TFSA contribution, therefore, we need to back up and recalculate
      # all amounts excluding the optional TFSA contribution.
      account_transactions_excluding_tfsa_contribution
    end

    def account_transactions_excluding_tfsa_contribution
      selected_accounts = []
      remaining_needed = 0

      rrsp_withdrawal = withdrawal_amounts.annual_rrsp(exclude_tfsa_contribution: true)

      # Simplest case: RRSP has enough for everything, we're done
      if rrsp_account.balance >= rrsp_withdrawal
        selected_accounts << { account: rrsp_account, amount: rrsp_withdrawal }
        return selected_accounts
      end

      # Otherwise drain what's left (if there's more than zero) and calculate how much more is needed
      if rrsp_account.balance.positive? && rrsp_account.balance < rrsp_withdrawal
        selected_accounts << { account: rrsp_account, amount: rrsp_account.balance }
        after_tax_rrsp_amt = @tax_calculator.calculate(rrsp_account.balance, app_config["province_code"])[:take_home]
        remaining_needed = withdrawal_amounts.annual_taxable(exclude_tfsa_contribution: true) - after_tax_rrsp_amt
      end

      # If there's nothing left in RRSP, then we need to lean on the next account for the whole thing
      if rrsp_account.balance.zero?
        remaining_needed = withdrawal_amounts.annual_taxable(exclude_tfsa_contribution: true)
      end

      # Try to use taxable account
      if remaining_needed.positive? && taxable_account.balance.positive?
        taxable_withdrawal = [taxable_account.balance, remaining_needed].min
        selected_accounts << { account: taxable_account, amount: taxable_withdrawal }
        remaining_needed -= taxable_withdrawal
      end

      # Try to use tfsa account
      if remaining_needed.positive? && tfsa_account.balance.positive?
        tfsa_withdrawal = [tfsa_account.balance, remaining_needed].min
        selected_accounts << { account: tfsa_account, amount: tfsa_withdrawal }
        remaining_needed -= tfsa_withdrawal
      end

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

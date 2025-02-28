# frozen_string_literal: true

module Strategy
  # TODO: 26 - Testing of this is covered in Strategy::RrspToTaxableToTfsa because this got extracted later.
  # But the mandatory rrif logic is new and should be tested directly here.
  # Handles the logic of determining withdrawal amounts and order.
  # Doesn't actually affect any account balances, this is just doing the planning work.
  # - Withdraw from RRSP first, considering taxes
  # - Then withdraw from Taxable if needed
  # - Finally, withdraw from TFSA as a last resort
  # - Returns a structured list of planned transactions
  class WithdrawalPlanner
    def initialize(withdrawal_amounts, rrsp_account, taxable_account, tfsa_account, province_code)
      @withdrawal_amounts = withdrawal_amounts
      @rrsp_account = rrsp_account
      @taxable_account = taxable_account
      @tfsa_account = tfsa_account
      @tax_calculator = Tax::IncomeTaxCalculator.new
      @rrif_calculator = Strategy::RRIFWithdrawalCalculator.new
      @province_code = province_code
    end

    # TODO: 26 - consider new model AccountTransactions and return array of those rather than hashes?
    # Determines the withdrawals needed from RRSP, Taxable, and TFSA
    # Returns an array of { account: account, amount: amount } hashes
    # If all accounts are exhausted and funds are still needed, returns an empty array
    def plan_withdrawals
      selected_accounts, remaining_needed = attempt_withdrawals(exclude_tfsa_contribution: false)

      # If we had to use TFSA, retry excluding TFSA contribution to preserve TFSA where possible
      if selected_accounts.any? { |entry| entry[:account] == @tfsa_account }
        selected_accounts, remaining_needed = attempt_withdrawals(exclude_tfsa_contribution: true)
      end

      # If we still need more funds after trying all accounts, return an empty array (out of money)
      remaining_needed.positive? ? [] : selected_accounts
    end

    private

    attr_reader :withdrawal_amounts, :rrif_calculator, :rrsp_account, :taxable_account, :tfsa_account, :province_code

    # Attempts to withdraw required funds in order (RRSP -> Taxable -> TFSA)
    # exclude_tfsa_contribution: if true, does not factor in TFSA contributions
    # Returns an array of planned withdrawals and the remaining shortfall (if any)
    def attempt_withdrawals(exclude_tfsa_contribution:)
      selected_accounts = []
      remaining_needed = withdraw_from_rrsp(selected_accounts, exclude_tfsa_contribution)

      # If RRSP covered everything, exit early
      return [selected_accounts, remaining_needed] if remaining_needed.zero?

      selected_accounts, remaining_needed = withdraw_from_taxable(selected_accounts, remaining_needed)
      selected_accounts, remaining_needed = withdraw_from_tfsa(selected_accounts, remaining_needed)

      [selected_accounts, remaining_needed]
    end

    # TODO: 26 - rubocop complexity
    # TODO: 26 - it would be nice if we could also calculate the tax "leakage" from forced withdrawals
    # Attempts to withdraw from RRSP while accounting for tax implications and mandatory RRIF minimums.
    # If sufficient RRSP funds exist, withdraw full amount including taxes
    # If partial RRSP funds exist, withdraw everything and determine remaining shortfall
    # Returns remaining shortfall after RRSP withdrawal
    def withdraw_from_rrsp(selected_accounts, exclude_tfsa_contribution)
      gross_withdrawal = @withdrawal_amounts.annual_rrsp(exclude_tfsa_contribution: exclude_tfsa_contribution)
      actual_gross = gross_withdrawal
      forced_net_excess = 0

      # We only need to do something special if the mandatory is greater than 0 and greater than what we wanted
      # Furthermore, this is only a problem if rrsp has sufficient funds for what we wanted
      # Otherwise if it doesn't have enough, then we'd be draining it which would cover the mandatory percentage
      if mandatory_rrif_withdrawal > gross_withdrawal
        actual_gross = mandatory_rrif_withdrawal
        what_we_wanted_after_tax = after_tax_withdrawal(gross_withdrawal)
        what_we_will_actually_have_after_tax = after_tax_withdrawal(mandatory_rrif_withdrawal)
        forced_net_excess = what_we_will_actually_have_after_tax - what_we_wanted_after_tax
      end

      if rrsp_has_sufficient_funds?(actual_gross)
        withdraw_full_gross_from_rrsp(selected_accounts, actual_gross, forced_net_excess: forced_net_excess)
        return 0 # Fully covered
      elsif rrsp_has_partial_funds?
        return drain_rrsp(selected_accounts, exclude_tfsa_contribution) # Withdraw all RRSP, return remaining needed
      end

      # If we get here, it means RRSP is empty, so return the entire amount needed from taxable account
      @withdrawal_amounts.annual_taxable(exclude_tfsa_contribution: exclude_tfsa_contribution)
    end

    def mandatory_rrif_withdrawal
      age = withdrawal_amounts.current_age
      if rrif_calculator.mandatory_withdrawal?(age)
        rrif_calculator.withdrawal_amount(age, rrsp_account.balance)
      else
        0
      end
    end

    # Checks if RRSP has enough funds to cover gross withdrawal
    def rrsp_has_sufficient_funds?(gross_withdrawal)
      @rrsp_account.balance >= gross_withdrawal
    end

    # Checks if RRSP has any funds left
    def rrsp_has_partial_funds?
      @rrsp_account.balance.positive?
    end

    # Withdraws the full gross amount from RRSP and adds it to planned transactions
    def withdraw_full_gross_from_rrsp(selected_accounts, gross_withdrawal, forced_net_excess: 0)
      selected_accounts << { account: @rrsp_account, amount: gross_withdrawal, forced_net_excess: forced_net_excess }
    end

    # Drains RRSP and calculates the remaining shortfall after tax
    def drain_rrsp(selected_accounts, exclude_tfsa_contribution)
      selected_accounts << { account: @rrsp_account, amount: @rrsp_account.balance }
      after_tax = after_tax_withdrawal(@rrsp_account.balance)
      @withdrawal_amounts.annual_taxable(exclude_tfsa_contribution: exclude_tfsa_contribution) - after_tax
    end

    # Attempts to withdraw from Taxable account if needed
    # Withdraws the lesser of remaining shortfall or available balance
    def withdraw_from_taxable(selected_accounts, remaining_needed)
      return [selected_accounts, remaining_needed] if remaining_needed <= 0 || @taxable_account.balance.zero?

      taxable_withdrawal = [@taxable_account.balance, remaining_needed].min
      selected_accounts << { account: @taxable_account, amount: taxable_withdrawal }
      remaining_needed -= taxable_withdrawal

      [selected_accounts, remaining_needed]
    end

    # Attempts to withdraw from TFSA if needed
    # TFSA is the last-resort account
    def withdraw_from_tfsa(selected_accounts, remaining_needed)
      return [selected_accounts, remaining_needed] if remaining_needed <= 0 || @tfsa_account.balance.zero?

      tfsa_withdrawal = [@tfsa_account.balance, remaining_needed].min
      selected_accounts << { account: @tfsa_account, amount: tfsa_withdrawal }
      remaining_needed -= tfsa_withdrawal

      [selected_accounts, remaining_needed]
    end

    # Computes after-tax amount from a given RRSP withdrawal
    def after_tax_withdrawal(amount)
      @tax_calculator.calculate(amount, province_code)[:take_home]
    end
  end
end

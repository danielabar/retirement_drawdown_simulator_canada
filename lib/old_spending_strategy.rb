# frozen_string_literal: true

class SpendingStrategy
  def initialize(cash_cushion, accounts, withdrawal_amounts, tax_rate, threshold)
    @cash_cushion = cash_cushion
    @accounts = accounts
    @withdrawal_amounts = withdrawal_amounts
    @tax_rate = tax_rate
    @threshold = threshold
  end

  # TODO: return what action happened for reporting - cash cushion vs investment account withdrawal?
  def execute(current_return, phase_name)
    if market_downturn?(current_return)
      withdraw_from_cash_cushion(phase_name)
    else
      withdraw_from_accounts(phase_name)
    end
  end

  private

  attr_reader :cash_cushion, :accounts, :withdrawal_amounts, :tax_rate, :threshold

  def market_downturn?(current_return)
    current_return < threshold
  end

  # TODO: don't bother withdrawing if there's 0 left in cash_cushion
  # TODO: how to have additional note recorded for simulation result?
  # Is `SpendingStrategy` to handle cash cushion, and all other decisions handled in Simulation the correct abstraction?
  def withdraw_from_cash_cushion(phase_name)
    amount_needed = withdrawal_amounts.annual_cash_cushion
    available_cash = cash_cushion.balance

    if available_cash >= amount_needed
      cash_cushion.withdraw(amount_needed)
      # puts "=== WITHDRAWAL FROM CASH CUSHION: #{NumericFormatter.format_currency(amount_needed)} ==="
    else
      # Partial withdrawal from cash cushion
      cash_cushion.withdraw(available_cash)
      # puts "=== WITHDRAWAL FROM CASH CUSHION: #{NumericFormatter.format_currency(available_cash)} ==="
      remaining_needed = amount_needed - available_cash

      # Fall back to accounts for remaining amount
      withdraw_from_accounts(phase_name, remaining_needed)
    end
  end

  def withdraw_from_accounts(phase_name, custom_amount = nil)
    amount_to_withdraw = custom_amount || withdrawal_amount_for_phase(phase_name)

    case phase_name
    when "RRSP Drawdown"
      pre_tax_withdrawal = amount_to_withdraw / (1 - tax_rate)
      accounts[:rrsp].withdraw(pre_tax_withdrawal)
    when "Taxable Drawdown"
      accounts[:taxable].withdraw(amount_to_withdraw)
    when "TFSA Drawdown"
      accounts[:tfsa].withdraw(amount_to_withdraw)
    end
  end

  def withdrawal_amount_for_phase(phase_name)
    case phase_name
    when "RRSP Drawdown"
      withdrawal_amounts.annual_rrsp
    when "Taxable Drawdown"
      withdrawal_amounts.annual_taxable
    when "TFSA Drawdown"
      withdrawal_amounts.annual_tfsa
    else
      0
    end
  end
end

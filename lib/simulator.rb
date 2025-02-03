# frozen_string_literal: true

# TODO: Need some sensible stopping point for all loops to avoid exceeding reasonable human lifetime.
class Simulator
  def initialize(plan)
    @plan = plan
    @age = plan.retirement_age
    @rrsp_account = plan.rrsp_account
    @taxable_account = plan.taxable_account
    @tfsa_account = plan.tfsa_account
    @results = []
  end

  def run
    simulate_rrsp_drawdown
    simulate_taxable_drawdown
    simulate_tfsa_drawdown
    @results
  end

  private

  def simulate_rrsp_drawdown
    while @rrsp_account.balance >= @plan.annual_withdrawal_amount_rrsp
      @rrsp_account.withdraw(@plan.annual_withdrawal_amount_rrsp)
      @tfsa_account.deposit(@plan.annual_tfsa_contribution)
      apply_growth
      record_yearly_status("RRSP Drawdown")
      @age += 1
    end
  end

  def simulate_taxable_drawdown
    while @taxable_account.balance >= @plan.annual_withdrawal_amount_taxable
      @taxable_account.withdraw(@plan.annual_withdrawal_amount_taxable)
      @tfsa_account.deposit(@plan.annual_tfsa_contribution)
      apply_growth
      record_yearly_status("Taxable Drawdown")
      @age += 1
    end
  end

  def simulate_tfsa_drawdown
    while @tfsa_account.balance >= @plan.annual_withdrawal_amount_tfsa
      @tfsa_account.withdraw(@plan.annual_withdrawal_amount_tfsa)
      apply_growth
      record_yearly_status("TFSA Drawdown")
      @age += 1
    end
  end

  def apply_growth
    @rrsp_account.apply_growth(@plan.annual_growth_rate)
    @taxable_account.apply_growth(@plan.annual_growth_rate)
    @tfsa_account.apply_growth(@plan.annual_growth_rate)
  end

  # They're all `yearly_status` type now
  def record_yearly_status(note)
    @results << {
      type: :yearly_status,
      age: @age,
      rrsp_balance: @rrsp_account.balance,
      tfsa_balance: @tfsa_account.balance,
      taxable_balance: @taxable_account.balance,
      note: note
    }
  end
end

# frozen_string_literal: true

require_relative "retirement_plan"

class Simulator
  def initialize(plan)
    @plan = plan
    @age = plan.retirement_age
    @rrsp_balance = plan.rrsp_balance
    @taxable_balance = plan.taxable_balance
    @tfsa_balance = plan.tfsa_balance
    @results = []
  end

  def run
    add_summary
    simulate_rrsp_drawdown
    simulate_taxable_drawdown
    simulate_tfsa_drawdown
    @results
  end

  private

  def add_summary
    @results << {
      type: :summary,
      desired_income: @plan.desired_income,
      rrsp_withholding_tax: @plan.tax_withholding,
      expected_refund: @plan.expected_refund,
      rrsp_available_after_tax: @plan.rrsp_withdrawal_actual_amount_available,
      amount_available_subsequent_years: @plan.amount_available_subsequent_years
    }
  end

  def simulate_rrsp_drawdown
    while @rrsp_balance >= @plan.annual_withdrawal_amount_rrsp
      @rrsp_balance -= @plan.annual_withdrawal_amount_rrsp
      @tfsa_balance += @plan.annual_tfsa_contribution
      apply_growth
      record_yearly_status("RRSP Drawdown")
      @age += 1
    end
  end

  def simulate_taxable_drawdown
    while @taxable_balance >= @plan.annual_withdrawal_amount_taxable
      @taxable_balance -= @plan.annual_withdrawal_amount_taxable
      @tfsa_balance += @plan.annual_tfsa_contribution
      apply_growth
      record_yearly_status("Taxable Drawdown")
      @age += 1
    end
  end

  def simulate_tfsa_drawdown
    while @tfsa_balance >= @plan.annual_withdrawal_amount_tfsa
      @tfsa_balance -= @plan.annual_withdrawal_amount_tfsa
      apply_growth
      record_yearly_status("TFSA Drawdown")
      @age += 1
    end
  end

  def apply_growth
    @rrsp_balance *= (1 + @plan.annual_growth_rate)
    @taxable_balance *= (1 + @plan.annual_growth_rate)
    @tfsa_balance *= (1 + @plan.annual_growth_rate)
  end

  def record_yearly_status(note)
    @results << {
      type: :yearly_status,
      age: @age,
      rrsp_balance: @rrsp_balance,
      tfsa_balance: @tfsa_balance,
      taxable_balance: @taxable_balance,
      note: note
    }
  end
end

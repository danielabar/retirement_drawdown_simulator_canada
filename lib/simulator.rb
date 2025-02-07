# frozen_string_literal: true

class Simulator
  def initialize(plan)
    @plan = plan
    @age = plan.retirement_age
    @max_age = plan.max_age
    @rrsp_account = plan.rrsp_account
    @taxable_account = plan.taxable_account
    @tfsa_account = plan.tfsa_account
    @results = []
  end

  def run
    @return_sequence = ReturnSequence.new(@age, @max_age, @plan.annual_growth_rate["average"],
                                          @plan.annual_growth_rate["min"], @plan.annual_growth_rate["max"])
    simulate_rrsp_drawdown
    simulate_taxable_drawdown
    simulate_tfsa_drawdown
    @results
  end

  private

  def simulate_rrsp_drawdown
    while @rrsp_account.balance >= @plan.annual_withdrawal_amount_rrsp && @age < @plan.max_age
      @rrsp_account.withdraw(@plan.annual_withdrawal_amount_rrsp)
      @tfsa_account.deposit(@plan.annual_tfsa_contribution)
      current_return = apply_growth
      record_yearly_status("RRSP Drawdown", current_return)
      @age += 1
    end
    record_yearly_status("Exited RRSP Drawdown due to reaching max age", current_return) if @age >= @plan.max_age
  end

  def simulate_taxable_drawdown
    while @taxable_account.balance >= @plan.annual_withdrawal_amount_taxable && @age < @plan.max_age
      @taxable_account.withdraw(@plan.annual_withdrawal_amount_taxable)
      @tfsa_account.deposit(@plan.annual_tfsa_contribution)
      current_return = apply_growth
      record_yearly_status("Taxable Drawdown", current_return)
      @age += 1
    end
    record_yearly_status("Exited Taxable Drawdown due to reaching max age", current_return) if @age >= @plan.max_age
  end

  def simulate_tfsa_drawdown
    while @tfsa_account.balance >= @plan.annual_withdrawal_amount_tfsa && @age < @plan.max_age
      @tfsa_account.withdraw(@plan.annual_withdrawal_amount_tfsa)
      current_return = apply_growth
      record_yearly_status("TFSA Drawdown", current_return)
      @age += 1
    end
    record_yearly_status("Exited TFSA Drawdown due to reaching max age", current_return) if @age >= @plan.max_age
  end

  def apply_growth
    current_return = @return_sequence.get_return_for_age(@age)
    @rrsp_account.apply_growth(current_return)
    @taxable_account.apply_growth(current_return)
    @tfsa_account.apply_growth(current_return)
    current_return
  end

  # They're all `yearly_status` type now
  def record_yearly_status(note, rate_of_return)
    @results << {
      type: :yearly_status,
      age: @age,
      rrsp_balance: @rrsp_account.balance,
      tfsa_balance: @tfsa_account.balance,
      taxable_balance: @taxable_account.balance,
      note: note,
      rate_of_return: rate_of_return
    }
  end
end

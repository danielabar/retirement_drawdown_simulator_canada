# frozen_string_literal: true

class FirstYearCashFlow
  def initialize(plan)
    @desired_income = plan.desired_income
    @withholding_rate = plan.rrsp_withholding_tax_rate
    @actual_tax_bill = plan.actual_tax_bill
    @withdrawal_amount = plan.annual_withdrawal_amount_rrsp
  end

  def calculate
    [
      ["Desired Income Including TFSA Contribution", @desired_income],
      ["RRSP Withholding Tax", rrsp_withholding_tax],
      ["Expected Tax Refund", expected_refund],
      ["RRSP Available After Withholding", rrsp_available_after_tax],
      ["Required Cash Buffer for First Year", required_cash_buffer]
    ]
  end

  private

  def rrsp_withholding_tax
    @withdrawal_amount * @withholding_rate
  end

  def rrsp_available_after_tax
    @withdrawal_amount - rrsp_withholding_tax
  end

  def expected_refund
    rrsp_withholding_tax - @actual_tax_bill
  end

  def required_cash_buffer
    @desired_income - rrsp_available_after_tax
  end
end

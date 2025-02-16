# frozen_string_literal: true

class FirstYearCashFlow
  def initialize(app_config)
    @app_config = app_config
    @reverse_tax_calculator = Tax::ReverseIncomeTaxCalculator.new
  end

  def calculate
    [
      ["Desired Income Including TFSA Contribution", desired_income],
      ["RRSP Withdrawal Amount (higher due to income tax)", annual_withdrawal_amount_rrsp],
      ["RRSP Withholding Tax", rrsp_withholding_tax],
      ["Actual Tax Bill", actual_tax_bill],
      ["Expected Tax Refund", expected_refund],
      ["RRSP Available After Withholding", rrsp_available_after_tax],
      ["Required Cash Buffer for First Year", required_cash_buffer]
    ]
  end

  private

  attr_reader :app_config

  # This is the after-tax desired income
  def desired_income
    app_config["desired_spending"] + app_config["annual_tfsa_contribution"]
  end

  # This is the before-tax withdrawal amount because RRSP withdrawals are taxed as regular income
  def annual_withdrawal_amount_rrsp
    reverse_tax_results[:gross_income]
  end

  def rrsp_withholding_tax
    annual_withdrawal_amount_rrsp * app_config.taxes["rrsp_withholding_rate"]
  end

  def rrsp_available_after_tax
    annual_withdrawal_amount_rrsp - rrsp_withholding_tax
  end

  def expected_refund
    rrsp_withholding_tax - actual_tax_bill
  end

  def actual_tax_bill
    reverse_tax_results[:total_tax]
  end

  def required_cash_buffer
    desired_income - rrsp_available_after_tax
  end

  def reverse_tax_results
    @reverse_tax_results ||= @reverse_tax_calculator.calculate(desired_income, app_config["province_code"])
  end
end

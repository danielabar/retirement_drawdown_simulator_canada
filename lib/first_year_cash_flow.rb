# frozen_string_literal: true

class FirstYearCashFlow
  def initialize(app_config)
    @app_config = app_config
  end

  def calculate
    [
      ["Desired Income Including TFSA Contribution", desired_income],
      ["RRSP Withholding Tax", rrsp_withholding_tax],
      ["Expected Tax Refund", expected_refund],
      ["RRSP Available After Withholding", rrsp_available_after_tax],
      ["Required Cash Buffer for First Year", required_cash_buffer]
    ]
  end

  private

  attr_reader :app_config

  def desired_income
    app_config["desired_spending"] + app_config["annual_tfsa_contribution"]
  end

  def rrsp_withholding_tax
    app_config["annual_withdrawal_amount_rrsp"] * app_config.taxes["rrsp_withholding_rate"]
  end

  def rrsp_available_after_tax
    app_config["annual_withdrawal_amount_rrsp"] - rrsp_withholding_tax
  end

  def expected_refund
    rrsp_withholding_tax - app_config.taxes["actual_tax_bill"]
  end

  def required_cash_buffer
    desired_income - rrsp_available_after_tax
  end
end

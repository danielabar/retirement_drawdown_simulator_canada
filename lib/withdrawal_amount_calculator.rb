# frozen_string_literal: true

class WithdrawalAmountCalculator
  def initialize(app_config)
    @app_config = app_config
  end

  def annual_withdrawal_amount_rrsp
    @app_config["annual_withdrawal_amount_rrsp"]
  end

  def annual_withdrawal_amount_taxable
    @app_config["desired_spending"] + @app_config["annual_tfsa_contribution"]
  end

  def annual_withdrawal_amount_tfsa
    @app_config["desired_spending"]
  end
end

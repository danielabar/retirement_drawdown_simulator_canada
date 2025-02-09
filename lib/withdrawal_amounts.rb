# frozen_string_literal: true

class WithdrawalAmounts
  def initialize(app_config)
    @app_config = app_config
  end

  def annual_rrsp
    app_config["annual_withdrawal_amount_rrsp"]
  end

  def annual_taxable
    app_config["desired_spending"] + app_config["annual_tfsa_contribution"]
  end

  def annual_tfsa
    app_config["desired_spending"]
  end

  private

  attr_reader :app_config
end

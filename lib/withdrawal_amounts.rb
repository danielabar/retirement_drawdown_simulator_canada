# frozen_string_literal: true

class WithdrawalAmounts
  ACCOUNT_WITHDRAWAL_METHODS = {
    "rrsp" => :annual_rrsp,
    "taxable" => :annual_taxable,
    "tfsa" => :annual_tfsa,
    "cash_cushion" => :annual_cash_cushion
  }.freeze

  def initialize(app_config)
    @app_config = app_config
    @reverse_tax_calculator = Tax::ReverseIncomeTaxCalculator.new
  end

  def annual_amount(account)
    method_name = ACCOUNT_WITHDRAWAL_METHODS[account.name]
    raise ArgumentError, "Unknown account type: #{account.name}" unless method_name

    send(method_name)
  end

  def annual_rrsp
    reverse_tax_results[:gross_income]
  end

  def annual_taxable
    app_config["desired_spending"] + app_config["annual_tfsa_contribution"]
  end

  def annual_tfsa
    app_config["desired_spending"]
  end

  # If we're withdrawing from the cash cushion, it's because of a severe market downturn,
  # so we won't be making the optional TFSA contributions during this time.
  def annual_cash_cushion
    app_config["desired_spending"]
  end

  private

  attr_reader :app_config

  # TODO: Makes repeated simulations slow because this gets calculated each time
  def reverse_tax_results
    @reverse_tax_results ||= @reverse_tax_calculator.calculate(desired_income, app_config["province_code"])
  end

  def desired_income
    app_config["desired_spending"] + app_config["annual_tfsa_contribution"]
  end
end

# frozen_string_literal: true

class RetirementPlan
  attr_reader :retirement_age, :max_age, :return_sequence, :annual_tfsa_contribution,
              :desired_spending, :annual_withdrawal_amount_rrsp, :rrsp_account, :taxable_account, :tfsa_account,
              :rrsp_withholding_tax_rate, :actual_tax_bill, :market_price, :cost_per_share

  def initialize(config_path)
    config = YAML.load_file(config_path)
    load_config(config)
  end

  def desired_income
    @desired_spending + @annual_tfsa_contribution
  end

  def tax_withholding
    desired_income * @rrsp_withholding_tax_rate
  end

  def rrsp_withdrawal_actual_amount_available
    annual_withdrawal_amount_rrsp - tax_withholding
  end

  def expected_refund
    tax_withholding - @actual_tax_bill
  end

  def amount_available_subsequent_years
    rrsp_withdrawal_actual_amount_available + expected_refund
  end

  def capital_gains_tax
    acb_per_share = @market_price - @cost_per_share
    total_acb = acb_per_share * (desired_income / @market_price)
    (total_acb / 2).round(2) # 50% of capital gains is taxable
  end

  def annual_withdrawal_amount_taxable
    desired_income
  end

  def annual_withdrawal_amount_tfsa
    @desired_spending
  end

  private

  def load_config(config)
    load_general_settings(config)
    load_accounts(config["accounts"])
    load_growth_rates(config["annual_growth_rate"])
    load_taxes(config["taxes"])
    load_investments(config["investment"])
  end

  def load_general_settings(config)
    @retirement_age = config["retirement_age"]
    @max_age = config["max_age"]
    @annual_growth_rate = config["annual_growth_rate"]
    @annual_tfsa_contribution = config["annual_tfsa_contribution"]
    @desired_spending = config["desired_spending"]
    @annual_withdrawal_amount_rrsp = config["annual_withdrawal_amount_rrsp"]
  end

  def load_accounts(accounts)
    @rrsp_account = Account.new(accounts["rrsp"])
    @taxable_account = Account.new(accounts["taxable"])
    @tfsa_account = Account.new(accounts["tfsa"])
  end

  def load_growth_rates(growth_config)
    @return_sequence = ReturnSequence.new(
      @retirement_age,
      @max_age,
      growth_config["average"],
      growth_config["min"],
      growth_config["max"]
    )
  end

  def load_taxes(taxes)
    @rrsp_withholding_tax_rate = taxes["rrsp_withholding_rate"]
    @actual_tax_bill = taxes["actual_tax_bill"]
  end

  def load_investments(investment)
    @market_price = investment["market_price"]
    @cost_per_share = investment["cost_per_share"]
  end
end

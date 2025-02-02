require 'yaml'

class RetirementPlan
  attr_reader :retirement_age, :annual_growth_rate, :annual_tfsa_contribution,
              :desired_spending, :annual_withdrawal_amount_rrsp,:rrsp_balance, :taxable_balance, :tfsa_balance,
              :rrsp_withholding_tax_rate, :actual_tax_bill, :market_price, :cost_per_share

  def initialize(config_path)
    config = YAML.load_file(config_path)

    @retirement_age = config['retirement_age']
    @annual_growth_rate = config['annual_growth_rate']
    @annual_tfsa_contribution = config['annual_tfsa_contribution']
    @desired_spending = config['desired_spending']
    @annual_withdrawal_amount_rrsp = config['annual_withdrawal_amount_rrsp']

    @rrsp_balance = config['accounts']['rrsp']
    @taxable_balance = config['accounts']['taxable']
    @tfsa_balance = config['accounts']['tfsa']

    @rrsp_withholding_tax_rate = config['taxes']['rrsp_withholding_rate']
    @actual_tax_bill = config['taxes']['actual_tax_bill']

    @market_price = config['investment']['market_price']
    @cost_per_share = config['investment']['cost_per_share']
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

  # not used?
  def capital_gains_tax
    acb_per_share = @market_price - @cost_per_share
    total_acb = acb_per_share * (desired_income / @market_price)
    (total_acb / 2).round(2) # 50% of capital gains is taxable
  end

  # Assumption: Given low-ish amount ~40K,
  # capital gains @50% inclusion likely to be below basic personal credit
  # Also assuming this is the only source of income during this phase
  # If we factor in CPP, will need to adjust this
  def annual_withdrawal_amount_taxable
    desired_income
  end

  def annual_withdrawal_amount_tfsa
    @desired_spending
  end
end

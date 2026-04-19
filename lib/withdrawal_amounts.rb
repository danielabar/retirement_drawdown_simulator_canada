# frozen_string_literal: true

class WithdrawalAmounts # rubocop:disable Metrics/ClassLength
  ACCOUNT_WITHDRAWAL_METHODS = {
    "rrsp" => :annual_rrsp,
    "taxable" => :annual_taxable,
    "tfsa" => :annual_tfsa,
    "cash_cushion" => :annual_cash_cushion
  }.freeze

  MAX_ITERATIONS_FOR_RRSP_WITH_CPP = 100
  TOLERANCE_FOR_RRSP_WITH_CPP = 1.0

  attr_accessor :current_age, :annuity_active

  def initialize(app_config)
    @app_config = app_config
    @reverse_tax_calculator = Tax::ReverseIncomeTaxCalculator.new
    @tax_calculator = Tax::IncomeTaxCalculator.new
    @oas_config = OasConfig.new
    @annuity_active = false
  end

  def annual_rrsp(exclude_tfsa_contribution: false)
    unless cpp_used? || oas_used? || annuity_used?
      return reverse_tax_results(exclude_tfsa_contribution: exclude_tfsa_contribution)[:gross_income]
    end

    candidate_rrsp_withdrawal_upper = reverse_tax_results[:gross_income]
    candidate_rrsp_withdrawal_lower = candidate_rrsp_withdrawal_upper - total_other_gross_income

    binary_search_rrsp_withdrawal(candidate_rrsp_withdrawal_upper,
                                  candidate_rrsp_withdrawal_lower)
  end

  def cpp_annual_gross_income
    app_config.cpp["monthly_amount"] * 12
  end

  def cpp_used?
    app_config.cpp["monthly_amount"].positive? && current_age >= app_config.cpp["start_age"]
  end

  def oas_annual_gross_income
    return 0 unless oas_used?

    oas = app_config.oas
    years = [oas["years_in_canada_after_18"], @oas_config.full_pension_residency_years].min
    (years.to_f / @oas_config.full_pension_residency_years) *
      @oas_config.base_monthly_amount(current_age) *
      @oas_config.deferral_multiplier(oas["start_age"]) * 12
  end

  def oas_used?
    years = app_config.oas&.dig("years_in_canada_after_18").to_i
    years >= @oas_config.minimum_residency_years && current_age >= app_config.oas["start_age"]
  end

  # Checks both config AND whether the annuity was actually purchased.
  # The annuity_active flag is set by the strategy layer after a successful
  # lump sum withdrawal from the RRSP. When the RRSP balance is insufficient
  # at purchase_age (e.g. due to poor market returns in simulation mode),
  # the purchase is skipped and this flag remains false — preventing the
  # withdrawal math from subtracting annuity income that doesn't exist.
  def annuity_used?
    annuity = app_config.annuity
    return false unless annuity
    return false unless @annuity_active

    annuity["monthly_payment"]&.positive? == true && current_age >= annuity["purchase_age"]
  end

  def annuity_annual_gross_income
    app_config.annuity["monthly_payment"] * 12
  end

  # TODO: At some point will have to deal with capital gains tax
  # but for now, assume whatever amount of ETFs selling for income from taxable account
  # isn't high enough to trigger any additional taxes.
  def annual_taxable(exclude_tfsa_contribution: false)
    interim_amt = if exclude_tfsa_contribution
                    app_config["desired_spending"]
                  else
                    app_config["desired_spending"] + app_config["annual_tfsa_contribution"]
                  end
    interim_amt -= cpp_annual_net_income if cpp_used?
    interim_amt -= oas_annual_net_income if oas_used?
    interim_amt -= annuity_annual_net_income if annuity_used?
    interim_amt
  end

  def annual_tfsa
    result = app_config["desired_spending"]
    result -= cpp_annual_net_income if cpp_used?
    result -= oas_annual_net_income if oas_used?
    result -= annuity_annual_net_income if annuity_used?
    result
  end

  # If we're withdrawing from the cash cushion, it's because of a severe market downturn,
  # so we won't be making the optional TFSA contributions during this time.
  def annual_cash_cushion
    result = app_config["desired_spending"]
    result -= cpp_annual_net_income if cpp_used?
    result -= oas_annual_net_income if oas_used?
    result -= annuity_annual_net_income if annuity_used?
    result
  end

  def desired_income
    app_config["desired_spending"] + app_config["annual_tfsa_contribution"]
  end

  private

  attr_reader :app_config

  def total_other_gross_income
    cpp_annual_gross_income +
      oas_annual_gross_income +
      (annuity_used? ? annuity_annual_gross_income : 0)
  end

  def binary_search_rrsp_withdrawal(upper_bound, lower_bound)
    iterations = 0
    candidate_rrsp_withdrawal = nil

    loop do
      candidate_rrsp_withdrawal = (upper_bound.to_f + lower_bound.to_f) / 2

      difference = actual_take_home(candidate_rrsp_withdrawal) - desired_income

      break if difference.abs <= TOLERANCE_FOR_RRSP_WITH_CPP || iterations >= MAX_ITERATIONS_FOR_RRSP_WITH_CPP

      if difference.positive?
        upper_bound = candidate_rrsp_withdrawal
      else
        lower_bound = candidate_rrsp_withdrawal
      end

      iterations += 1
    end

    candidate_rrsp_withdrawal
  end

  def actual_take_home(candidate_rrsp_withdrawal)
    total_taxable_income = candidate_rrsp_withdrawal
    total_taxable_income += cpp_annual_gross_income if cpp_used?
    total_taxable_income += oas_annual_gross_income if oas_used?
    total_taxable_income += annuity_annual_gross_income if annuity_used?
    @tax_calculator.calculate(total_taxable_income, app_config["province_code"])[:take_home]
  end

  def reverse_tax_results(exclude_tfsa_contribution: false)
    income = exclude_tfsa_contribution ? desired_income_excluding_tfsa_contribution : desired_income
    @reverse_tax_calculator.calculate(income, app_config["province_code"])
  end

  def desired_income_excluding_tfsa_contribution
    app_config["desired_spending"]
  end

  def cpp_annual_net_income
    @tax_calculator.calculate(cpp_annual_gross_income, app_config["province_code"])[:take_home]
  end

  def oas_annual_net_income
    @tax_calculator.calculate(oas_annual_gross_income, app_config["province_code"])[:take_home]
  end

  def annuity_annual_net_income
    @tax_calculator.calculate(annuity_annual_gross_income, app_config["province_code"])[:take_home]
  end
end

# frozen_string_literal: true

class WithdrawalAmounts
  ACCOUNT_WITHDRAWAL_METHODS = {
    "rrsp" => :annual_rrsp,
    "taxable" => :annual_taxable,
    "tfsa" => :annual_tfsa,
    "cash_cushion" => :annual_cash_cushion
  }.freeze

  MAX_ITERATIONS_FOR_RRSP_WITH_CPP = 100
  TOLERANCE_FOR_RRSP_WITH_CPP = 1.0

  attr_accessor :current_age

  def initialize(app_config)
    @app_config = app_config
    @reverse_tax_calculator = Tax::ReverseIncomeTaxCalculator.new
    @tax_calculator = Tax::IncomeTaxCalculator.new
  end

  def annual_rrsp(exclude_tfsa_contribution: false)
    return reverse_tax_results(exclude_tfsa_contribution: exclude_tfsa_contribution)[:gross_income] unless cpp_used?

    # Upper and lower bounds based on CPP and RRSP withdrawal
    # The upper bound is as if we didn't have CPP at all
    # The lower bound is as if we could subtract off the full gross CPP
    # but we can't actually do this since both rrsp withdrawal and CPP are taxable
    # so the real number lies somewhere in between these two.
    candidate_rrsp_withdrawal_upper = reverse_tax_results[:gross_income]
    candidate_rrsp_withdrawal_lower = reverse_tax_results[:gross_income] - cpp_annual_gross_income

    binary_search_rrsp_withdrawal(candidate_rrsp_withdrawal_upper,
                                  candidate_rrsp_withdrawal_lower)
  end

  def cpp_annual_gross_income
    app_config.cpp["monthly_amount"] * 12
  end

  def cpp_used?
    app_config.cpp["monthly_amount"].positive? && current_age >= app_config.cpp["start_age"]
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
    cpp_used? ? interim_amt - cpp_annual_net_income : interim_amt
  end

  def annual_tfsa
    cpp_used? ? app_config["desired_spending"] - cpp_annual_net_income : app_config["desired_spending"]
  end

  # If we're withdrawing from the cash cushion, it's because of a severe market downturn,
  # so we won't be making the optional TFSA contributions during this time.
  def annual_cash_cushion
    cpp_used? ? app_config["desired_spending"] - cpp_annual_net_income : app_config["desired_spending"]
  end

  def desired_income
    app_config["desired_spending"] + app_config["annual_tfsa_contribution"]
  end

  private

  attr_reader :app_config

  def binary_search_rrsp_withdrawal(upper_bound, lower_bound)
    iterations = 0
    candidate_rrsp_withdrawal = nil

    loop do
      # Calculate the midpoint RRSP withdrawal
      candidate_rrsp_withdrawal = (upper_bound.to_f + lower_bound.to_f) / 2

      # Check if take-home is close enough to desired spending
      difference = actual_take_home(candidate_rrsp_withdrawal) - desired_income

      break if difference.abs <= TOLERANCE_FOR_RRSP_WITH_CPP || iterations >= MAX_ITERATIONS_FOR_RRSP_WITH_CPP

      if difference.positive?
        # Take-home is too high, adjust upper bound
        upper_bound = candidate_rrsp_withdrawal
      else
        # Take-home is too low, adjust lower bound
        lower_bound = candidate_rrsp_withdrawal
      end

      iterations += 1
    end

    candidate_rrsp_withdrawal
  end

  def actual_take_home(candidate_rrsp_withdrawal)
    total_taxable_income = cpp_annual_gross_income + candidate_rrsp_withdrawal
    forward_tax_details = @tax_calculator.calculate(total_taxable_income, app_config["province_code"])
    forward_tax_details[:take_home]
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
end

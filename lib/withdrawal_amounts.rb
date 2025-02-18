# frozen_string_literal: true

class WithdrawalAmounts
  ACCOUNT_WITHDRAWAL_METHODS = {
    "rrsp" => :annual_rrsp,
    "taxable" => :annual_taxable,
    "tfsa" => :annual_tfsa,
    "cash_cushion" => :annual_cash_cushion
  }.freeze

  attr_accessor :current_age

  def initialize(app_config)
    @app_config = app_config
    @reverse_tax_calculator = Tax::ReverseIncomeTaxCalculator.new
  end

  def annual_amount(account)
    method_name = ACCOUNT_WITHDRAWAL_METHODS[account.name]
    raise ArgumentError, "Unknown account type: #{account.name}" unless method_name

    send(method_name)
  end

  # TODO: If cpp is not in effect (not being of age or cpp amount is 0, return: `reverse_tax_results[:gross_income]`
  # TODO: refactor to address complexity (later, after testing)
  # TODO: taxable, tfsa, and cash_cushion withdrawals also have to be adjusted for CPP
  def annual_rrsp
    cpp_start_age = app_config.cpp["start_age"]
    cpp_gross_annual = app_config.cpp["monthly_amount"] * 12

    # TODO: This should be desired_income because it could include optional TFSA contribution
    # desired_spending = app_config["desired_spending"]

    # If current_age is less than cpp_start_age, CPP is not in effect
    cpp_annual_income = current_age >= cpp_start_age ? cpp_gross_annual : 0

    # Initial guess (without CPP)
    rrsp_withdrawal = reverse_tax_results[:gross_income]

    # Upper and lower bounds based on CPP and RRSP withdrawal
    candidate_rrsp_withdrawal = nil
    candidate_rrsp_withdrawal_upper = rrsp_withdrawal
    candidate_rrsp_withdrawal_lower = rrsp_withdrawal - cpp_annual_income

    # Binary search to find the correct RRSP withdrawal
    tolerance = 1.0 # Allowable margin of error (i.e., desired spending)
    max_iterations = 100
    iterations = 0

    loop do
      # Calculate the midpoint RRSP withdrawal
      candidate_rrsp_withdrawal = (candidate_rrsp_withdrawal_upper + candidate_rrsp_withdrawal_lower) / 2

      # Total taxable income: CPP (if applicable) + RRSP withdrawal
      total_taxable_income = cpp_annual_income + candidate_rrsp_withdrawal
      forward_tax_details = Tax::IncomeTaxCalculator.new.calculate(total_taxable_income, app_config["province_code"])

      # Actual take-home income after tax
      actual_take_home = forward_tax_details[:take_home]

      # Check if take-home is close enough to desired spending
      difference = actual_take_home - desired_income

      break if difference.abs <= tolerance || iterations >= max_iterations

      if difference.positive?
        # Take-home is too high, adjust upper bound
        candidate_rrsp_withdrawal_upper = candidate_rrsp_withdrawal
      else
        # Take-home is too low, adjust lower bound
        candidate_rrsp_withdrawal_lower = candidate_rrsp_withdrawal
      end

      iterations += 1
    end

    # Return the final RRSP withdrawal after the loop
    candidate_rrsp_withdrawal
  end

  def annual_rrsp_original
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

  attr_reader :app_config, :current_age

  def reverse_tax_results
    @reverse_tax_results ||= @reverse_tax_calculator.calculate(desired_income, app_config["province_code"])
  end

  def desired_income
    app_config["desired_spending"] + app_config["annual_tfsa_contribution"]
  end

  # TODO: This is only for adjusting taxable, tfsa, and cash_cushion withdrawals (not RRSP withdrawals which are a different beast)
  # but this is not quite right because cpp_annual_income is a gross amount and is taxable.
  # If we assume that all other withdrawals end up not taxable (assume capital gains would be low enough for now),
  # then we need to simply apply the forward tax calculator to cpp_annual_income to arrive at the net amount.
  # Reduce required spending by CPP income if CPP is active
  def adjusted_spending
    app_config["desired_spending"] - cpp_annual_income
  end

  # TODO: this is actually gross, need to work in forward tax calculator to return net amount.
  # Note that applying forward tax calc to just the CPP amount would only be correct if that's the only source of income.
  # TODO: This is only going to work once we can guarantee to have a current_age
  def cpp_annual_income
    return 0 if current_age < app_config["cpp"]["start_age"]

    app_config["cpp"]["monthly_amount"] * 12
  end
end

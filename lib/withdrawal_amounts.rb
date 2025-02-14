# frozen_string_literal: true

class WithdrawalAmounts
  def initialize(app_config)
    @app_config = app_config
  end

  def annual_amount(account)
    case account.name
    when "rrsp"
      annual_rrsp
    when "taxable"
      annual_taxable
    when "tfsa"
      annual_tfsa
    when "cash_cushion"
      annual_cash_cushion
    else
      raise ArgumentError, "Unknown account type: #{account.name}"
    end
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

  # If we're withdrawing from the cash cushion, it's because of a severe market downturn,
  # so we won't be making the optional TFSA contributions during this time.
  def annual_cash_cushion
    app_config["desired_spending"]
  end

  private

  attr_reader :app_config
end

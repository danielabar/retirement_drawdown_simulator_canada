# frozen_string_literal: true

class WithdrawalRateCalculator
  def initialize(app_config)
    @desired_spending = app_config["desired_spending"]
    @accounts = load_accounts(app_config)
  end

  def calculate
    total_balance = @accounts.sum(&:balance)
    return 0.0 if total_balance.zero?

    @desired_spending / total_balance.to_f
  end

  private

  def load_accounts(app_config)
    [
      create_account("rrsp", app_config),
      create_account("taxable", app_config),
      create_account("tfsa", app_config)
    ]
  end

  def create_account(name, app_config)
    Account.new(name, app_config.accounts[name])
  end
end

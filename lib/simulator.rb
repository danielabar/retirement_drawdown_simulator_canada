# frozen_string_literal: true

class Simulator
  attr_reader :app_config, :retirement_age, :max_age, :return_sequence, :results, :rrsp_account, :taxable_account,
              :tfsa_account

  attr_accessor :current_age

  def initialize(app_config)
    @app_config = app_config

    @retirement_age = app_config["retirement_age"]
    @max_age = app_config["max_age"]
    @current_age = app_config["retirement_age"]

    load_return_sequence
    load_accounts

    @results = []
  end

  def run
    simulate_rrsp_drawdown
    simulate_taxable_drawdown
    simulate_tfsa_drawdown
    @results
  end

  private

  def load_return_sequence
    @return_sequence = ReturnSequence.new(@retirement_age, @max_age,
                                          @app_config.annual_growth_rate["average"],
                                          @app_config.annual_growth_rate["min"],
                                          @app_config.annual_growth_rate["max"])
  end

  def load_accounts
    @rrsp_account = Account.new(@app_config.accounts["rrsp"])
    @taxable_account = Account.new(@app_config.accounts["taxable"])
    @tfsa_account = Account.new(@app_config.accounts["tfsa"])
  end

  def simulate_rrsp_drawdown
    while rrsp_account.balance >= app_config["annual_withdrawal_amount_rrsp"] && current_age < max_age
      rrsp_account.withdraw(app_config["annual_withdrawal_amount_rrsp"])
      tfsa_account.deposit(app_config["annual_tfsa_contribution"])
      current_return = apply_growth
      record_yearly_status("RRSP Drawdown", current_return)
      self.current_age += 1
    end
    record_yearly_status("Exited RRSP Drawdown due to reaching max age", current_return) if current_age >= max_age
  end

  def simulate_taxable_drawdown
    while taxable_account.balance >= annual_withdrawal_amount_taxable && self.current_age < max_age
      taxable_account.withdraw(annual_withdrawal_amount_taxable)
      tfsa_account.deposit(app_config["annual_tfsa_contribution"])
      current_return = apply_growth
      record_yearly_status("Taxable Drawdown", current_return)
      self.current_age += 1
    end
    record_yearly_status("Exited Taxable Drawdown due to reaching max age", current_return) if current_age >= max_age
  end

  def simulate_tfsa_drawdown
    while tfsa_account.balance >= annual_withdrawal_amount_tfsa && current_age < max_age
      tfsa_account.withdraw(annual_withdrawal_amount_tfsa)
      current_return = apply_growth
      record_yearly_status("TFSA Drawdown", current_return)
      self.current_age += 1
    end
    record_yearly_status("Exited TFSA Drawdown due to reaching max age", current_return) if current_age >= max_age
  end

  def annual_withdrawal_amount_taxable
    desired_income
  end

  def annual_withdrawal_amount_tfsa
    app_config["desired_spending"]
  end

  def desired_income
    app_config["desired_spending"] + app_config["annual_tfsa_contribution"]
  end

  def apply_growth
    current_return = return_sequence.get_return_for_age(current_age)
    rrsp_account.apply_growth(current_return)
    taxable_account.apply_growth(current_return)
    tfsa_account.apply_growth(current_return)
    current_return
  end

  # They're all `yearly_status` type now
  def record_yearly_status(note, rate_of_return)
    results << {
      type: :yearly_status,
      age: current_age,
      rrsp_balance: rrsp_account.balance,
      tfsa_balance: tfsa_account.balance,
      taxable_balance: taxable_account.balance,
      note: note,
      rate_of_return: rate_of_return
    }
  end
end

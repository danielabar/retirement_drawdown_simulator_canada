# frozen_string_literal: true

class Simulator
  def initialize(app_config)
    @app_config = app_config
    @retirement_age = app_config["retirement_age"]
    @max_age = app_config["max_age"]
    @current_age = retirement_age
    @withdrawal_amounts = WithdrawalAmounts.new(app_config)

    load_return_sequence
    load_accounts

    @results = []
  end

  def run
    simulate_drawdown(rrsp_account, withdrawal_amounts.annual_rrsp, "RRSP Drawdown")
    simulate_drawdown(taxable_account, withdrawal_amounts.annual_taxable, "Taxable Drawdown")
    simulate_drawdown(tfsa_account, withdrawal_amounts.annual_tfsa, "TFSA Drawdown")
    results
  end

  private

  attr_accessor :current_age

  attr_reader :app_config, :retirement_age, :max_age, :return_sequence, :results, :rrsp_account, :taxable_account,
              :tfsa_account, :withdrawal_amounts

  def load_return_sequence
    @return_sequence = ReturnSequences::SequenceSelector.new(app_config, retirement_age, max_age).select
  end

  def load_accounts
    @rrsp_account = Account.new(app_config.accounts["rrsp"])
    @taxable_account = Account.new(app_config.accounts["taxable"])
    @tfsa_account = Account.new(app_config.accounts["tfsa"])
  end

  def simulate_drawdown(account, withdrawal_amount, phase_name)
    while account.balance >= withdrawal_amount && current_age < max_age
      process_year(account, withdrawal_amount, phase_name)
    end
    record_exit_if_max_age_reached(phase_name)
  end

  def process_year(account, withdrawal_amount, phase_name)
    account.withdraw(withdrawal_amount)
    handle_tfsa_contribution(phase_name)
    current_return = apply_growth
    record_yearly_status(phase_name, current_return)
    self.current_age += 1
  end

  def handle_tfsa_contribution(phase_name)
    # Only contribute to TFSA during RRSP or Taxable drawdown phases
    return unless ["RRSP Drawdown", "Taxable Drawdown"].include?(phase_name)

    tfsa_account.deposit(app_config["annual_tfsa_contribution"])
  end

  def apply_growth
    current_return = return_sequence.get_return_for_age(current_age)
    [rrsp_account, taxable_account, tfsa_account].each do |account|
      account.apply_growth(current_return)
    end
    current_return
  end

  def record_yearly_status(note, rate_of_return)
    results << {
      type: :yearly_status,
      age: current_age,
      rrsp_balance: rrsp_account.balance,
      tfsa_balance: tfsa_account.balance,
      taxable_balance: taxable_account.balance,
      note: note,
      rate_of_return: rate_of_return,
      total_balance: total_balance
    }
  end

  def total_balance
    rrsp_account.balance + taxable_account.balance + tfsa_account.balance
  end

  def record_exit_if_max_age_reached(phase_name)
    return unless current_age >= max_age

    record_yearly_status("Exited #{phase_name} due to reaching max age",
                         return_sequence.get_return_for_age(current_age))
  end
end

# frozen_string_literal: true

module Simulation
  class Simulator
    def initialize(app_config)
      @retirement_age = app_config["retirement_age"]
      @max_age = app_config["max_age"]
      @return_sequence = ReturnSequences::SequenceSelector.new(app_config, @retirement_age, @max_age).select
      @strategy = Strategy::RrspToTaxableToTfsa.new(app_config)
      @results = []
    end

    def run
      (retirement_age..max_age).each do |age|
        market_return = return_sequence.get_return_for_age(age)
        account = strategy.select_account(market_return)
        break if account.nil?

        strategy.transact(account)
        strategy.apply_growth(market_return)
        record_yearly_status(age, account, market_return)
      end
      results
    end

    private

    attr_reader :retirement_age, :max_age, :return_sequence, :strategy, :results

    def record_yearly_status(age, account, market_return)
      results << {
        age: age,
        rrsp_balance: strategy.rrsp_account.balance,
        tfsa_balance: strategy.tfsa_account.balance,
        taxable_balance: strategy.taxable_account.balance,
        cash_cushion_balance: strategy.cash_cushion.balance,
        note: account.name,
        rate_of_return: market_return,
        total_balance: strategy.total_balance
      }
    end
  end
end

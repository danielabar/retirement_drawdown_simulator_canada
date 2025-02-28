# frozen_string_literal: true

module Simulation
  class Simulator
    def initialize(app_config)
      @app_config = app_config
      @retirement_age = app_config["retirement_age"]
      @max_age = app_config["max_age"]
      @return_sequence = ReturnSequences::SequenceSelector.new(app_config, @retirement_age, @max_age).select
      @strategy = Strategy::RrspToTaxableToTfsa.new(app_config)
      @results = []
    end

    def run
      (retirement_age..max_age).each do |age|
        populate_current_age(age)
        market_return = return_sequence.get_return_for_age(age)
        account_transactions = strategy.select_account_transactions(market_return)
        break if account_transactions.empty?

        # temp debug
        # print_transactions(age, account_transactions)
        strategy.transact(account_transactions)
        strategy.apply_growth(market_return)
        record_yearly_status(age, account_transactions, market_return, strategy)
      end

      build_results
    end

    private

    attr_reader :app_config, :strategy, :retirement_age, :max_age, :return_sequence, :results

    # call from run if need to troubleshoot
    def print_transactions(age, accounts)
      puts "Age: #{age}"
      accounts.each do |transaction|
        account_name = transaction[:account].name
        amount = NumericFormatter.format_currency(transaction[:amount])
        if transaction[:forced_net_excess]
          forced_net_excess = NumericFormatter.format_currency(transaction[:forced_net_excess])
        end

        # Print the basic transaction details
        print_details = "  #{account_name}: #{amount}"

        # If there's a forced excess, print it as well
        print_details += " (Forced Net Excess: #{forced_net_excess})"

        puts print_details
      end
      puts "-" * 30
    end

    def populate_current_age(age)
      strategy.current_age = age
    end

    # TODO: 26 - it would be nice to show the forced_net_excess deposit if its greater than 0
    def record_yearly_status(age, account_transactions, market_return, strategy)
      results << {
        age: age,
        rrsp_balance: strategy.rrsp_account.balance,
        tfsa_balance: strategy.tfsa_account.balance,
        taxable_balance: strategy.taxable_account.balance,
        cash_cushion_balance: strategy.cash_cushion.balance,
        note: account_transactions.map { |act| act[:account].name }.join(", "),
        cpp: strategy.cpp_used?,
        rate_of_return: market_return,
        total_balance: strategy.total_balance
      }
    end

    def build_results
      { yearly_results: results }
    end
  end
end

# frozen_string_literal: true

module Simulation
  class SimulatorFormatter
    def initialize(simulation_results, first_year_cash_flow_results, evaluator_results)
      @results = simulation_results
      @first_year_cash_flow_results = first_year_cash_flow_results
      @evaluator_results = evaluator_results
    end

    def print_all
      print_first_year_cash_flow
      print_header
      print_yearly_results
      print_simulation_evaluation
    end

    private

    def print_first_year_cash_flow
      puts "=== First-Year Cash Flow Breakdown ==="
      @first_year_cash_flow_results.each do |label, value|
        puts "#{label}: #{NumericFormatter.format_currency(value)}"
      end
      puts "-" * 160
    end

    def print_header
      puts formatted_header
      puts "-" * 160
    end

    def formatted_header
      format_header_string(
        age: "Age",
        rrsp: "RRSP",
        tfsa: "TFSA",
        taxable: "Taxable",
        cash_cushion: "Cash Cushion",
        cpp: "CPP Used",
        total_balance: "Total Balance",
        note: "Note",
        rate_of_return: "RoR"
      )
    end

    def print_yearly_results
      @results.each do |record|
        puts formatted_yearly_result(record)
      end
    end

    def formatted_yearly_result(record)
      format_header_string(
        age: record[:age],
        rrsp: NumericFormatter.format_currency(record[:rrsp_balance]),
        tfsa: NumericFormatter.format_currency(record[:tfsa_balance]),
        taxable: NumericFormatter.format_currency(record[:taxable_balance]),
        cash_cushion: NumericFormatter.format_currency(record[:cash_cushion_balance]),
        cpp: record[:cpp] ? "Yes" : "No",
        total_balance: NumericFormatter.format_currency(record[:total_balance]),
        note: record[:note],
        rate_of_return: NumericFormatter.format_percentage(record[:rate_of_return])
      )
    end

    def format_header_string(values)
      format(
        "%<age>-10s %<rrsp>-20s %<tfsa>-20s %<taxable>-20s %<cash_cushion>-20s " \
        "%<cpp>-10s %<total_balance>-20s %<note>-20s %<rate_of_return>10s",
        values
      )
    end

    def print_simulation_evaluation
      puts "-" * 160
      puts "Simulation Result: #{@evaluator_results[:success] ? 'Success' : 'Failure'}"
      puts @evaluator_results[:explanation]
      puts "Withdrawal Rate: #{NumericFormatter.format_percentage(@evaluator_results[:withdrawal_rate])}"
    end
  end
end

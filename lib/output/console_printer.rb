# frozen_string_literal: true

require "tty-table"

module Output
  class ConsolePrinter
    DASH_SEPARATOR = "-" * 100

    def initialize(simulation_output, first_year_cash_flow_results, evaluator_results, visual: true)
      @yearly_results = simulation_output[:yearly_results]
      @first_year_cash_flow_results = first_year_cash_flow_results
      @evaluator_results = evaluator_results
      @visual = visual
    end

    def print_all
      print_first_year_cash_flow
      print_yearly_results
      print_simulation_evaluation
      print_charts if @visual
    end

    private

    def print_first_year_cash_flow
      puts "=== First-Year Cash Flow Breakdown ==="
      table = TTY::Table.new(header: %w[Description Amount], rows: format_cash_flow_results)
      puts table.render(:unicode, alignment: %i[left right], padding: [0, 1, 0, 1])
    end

    def format_cash_flow_results
      @first_year_cash_flow_results.map do |label, value|
        [label, NumericFormatter.format_currency(value.round)]
      end
    end

    def print_yearly_results
      puts "=== Yearly Results ==="
      table = TTY::Table.new(header: formatted_header, rows: formatted_yearly_results)
      puts table.render(:unicode,
                        alignment: %i[left right right right right left right right left right],
                        padding: [0, 1, 0, 1])
    end

    def formatted_header
      ["Age", "Taxable", "TFSA", "RRSP", "Cash Cushion", "CPP Used", "Total Balance", "RRIF Excess", "Note", "RoR"]
    end

    def formatted_yearly_results
      @yearly_results.map do |record|
        [
          record[:age],
          NumericFormatter.format_currency(record[:taxable_balance].round),
          NumericFormatter.format_currency(record[:tfsa_balance].round),
          NumericFormatter.format_currency(record[:rrsp_balance].round),
          NumericFormatter.format_currency(record[:cash_cushion_balance].round),
          cpp_value(record),
          NumericFormatter.format_currency(record[:total_balance].round),
          NumericFormatter.format_currency(record[:rrif_forced_net_excess].round),
          record[:note],
          NumericFormatter.format_percentage(record[:rate_of_return])
        ]
      end
    end

    def cpp_value(record)
      record[:cpp] ? "Yes" : "No"
    end

    def print_simulation_evaluation
      success = @evaluator_results[:success]
      emoji = success ? "✅" : "❌"
      result_text = success ? "Success" : "Failure"
      puts "Simulation Result: #{emoji} #{result_text}"
      puts @evaluator_results[:explanation]
      puts "Withdrawal Rate: #{NumericFormatter.format_percentage(@evaluator_results[:withdrawal_rate])}"
      puts "Average Rate of Return: #{NumericFormatter.format_percentage(@evaluator_results[:average_rate_of_return])}"
    end

    def print_charts
      print_return_sequence_chart
      print_total_balance_chart
    end

    def print_return_sequence_chart
      ages = @yearly_results.map { |r| r[:age] }
      rate_of_returns = @yearly_results.map { |r| r[:rate_of_return] }
      ConsolePlotter.plot_return_sequence(ages, rate_of_returns)
    end

    def print_total_balance_chart
      ages = @yearly_results.map { |r| r[:age] }
      total_balances = @yearly_results.map { |r| r[:total_balance] }
      ConsolePlotter.plot_total_balance(ages, total_balances)
    end
  end
end

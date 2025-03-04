# frozen_string_literal: true

module Output
  class ConsolePrinter
    def initialize(summary, simulation_output, first_year_cash_flow_results, evaluator_results, visual: true)
      @summary = summary
      @yearly_results = simulation_output[:yearly_results]
      @first_year_cash_flow_results = first_year_cash_flow_results
      @evaluator_results = evaluator_results
      @visual = visual
    end

    def print_all
      print_summary
      print_first_year_cash_flow
      print_yearly_results
      print_simulation_evaluation
      print_charts if @visual
    end

    private

    def print_summary
      puts "=== Retirement Plan Summary ==="

      rows = @summary[:starting_balances].map do |account, balance|
        [account.capitalize, format_currency(balance)]
      end

      rows << ["Total Starting Balance", format_currency(@summary[:starting_total_balance])]
      rows << ["Intended Retirement Duration", "#{@summary[:intended_retirement_duration]} years"]

      balances_table = TTY::Table.new(header: %w[Description Value], rows: rows)
      puts balances_table.render(:unicode, alignment: %i[left right], padding: [0, 1, 0, 1])
    end

    def print_first_year_cash_flow
      puts "=== First-Year Cash Flow Breakdown ==="
      table = TTY::Table.new(header: %w[Description Amount], rows: format_cash_flow_results)
      puts table.render(:unicode, alignment: %i[left right], padding: [0, 1, 0, 1])
    end

    def format_cash_flow_results
      @first_year_cash_flow_results.map do |label, value|
        [label, NumericFormatter.format_currency(value)]
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
      ["Age", "RRSP", "Taxable", "TFSA", "Cash Cushion", "CPP Used", "Total Balance", "RRIF Net Excess", "Note", "RoR"]
    end

    def formatted_yearly_results
      @yearly_results.map do |record|
        format_record(record)
      end
    end

    def format_record(record)
      [
        record[:age],
        format_currency(record[:rrsp_balance]),
        format_currency(record[:taxable_balance]),
        format_currency(record[:tfsa_balance]),
        format_currency(record[:cash_cushion_balance]),
        cpp_value(record),
        format_currency(record[:total_balance]),
        format_currency(record[:rrif_forced_net_excess]),
        record[:note],
        format_percentage(record[:rate_of_return])
      ]
    end

    def format_currency(value)
      NumericFormatter.format_currency(value)
    end

    def format_percentage(value)
      NumericFormatter.format_percentage(value)
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

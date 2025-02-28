# frozen_string_literal: true

module Output
  class ConsolePrinter
    DASH_SEPARATOR = "-" * 180

    def initialize(simulation_output, first_year_cash_flow_results, evaluator_results, visual: true)
      @yearly_results = simulation_output[:yearly_results]
      @first_year_cash_flow_results = first_year_cash_flow_results
      @evaluator_results = evaluator_results
      @visual = visual
    end

    def print_all
      print_first_year_cash_flow
      print_header
      print_yearly_results
      print_simulation_evaluation
      print_charts if @visual
    end

    private

    def print_first_year_cash_flow
      puts "=== First-Year Cash Flow Breakdown ==="
      @first_year_cash_flow_results.each do |label, value|
        puts "#{label}: #{NumericFormatter.format_currency(value)}"
      end
      puts DASH_SEPARATOR
    end

    def print_header
      puts formatted_header
      puts DASH_SEPARATOR
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
        rrif_forced_net_excess: "RRIF Excess",
        note: "Note",
        rate_of_return: "RoR"
      )
    end

    def print_yearly_results
      @yearly_results.each do |record|
        puts formatted_yearly_result(record)
      end
    end

    def formatted_yearly_result(record)
      formatted_values = format_yearly_values(record)
      format_header_string(formatted_values)
    end

    def format_yearly_values(record)
      {
        age: record[:age],
        rrsp: NumericFormatter.format_currency(record[:rrsp_balance]),
        tfsa: NumericFormatter.format_currency(record[:tfsa_balance]),
        taxable: NumericFormatter.format_currency(record[:taxable_balance]),
        cash_cushion: NumericFormatter.format_currency(record[:cash_cushion_balance]),
        cpp: cpp_value(record),
        total_balance: NumericFormatter.format_currency(record[:total_balance]),
        rrif_forced_net_excess: NumericFormatter.format_currency(record[:rrif_forced_net_excess]),
        note: record[:note],
        rate_of_return: NumericFormatter.format_percentage(record[:rate_of_return])
      }
    end

    def cpp_value(record)
      record[:cpp] ? "Yes" : "No"
    end

    def format_header_string(values)
      format(
        "%<age>-10s %<rrsp>-20s %<tfsa>-20s %<taxable>-20s %<cash_cushion>-20s " \
        "%<cpp>-10s %<total_balance>-20s %<rrif_forced_net_excess>-20s %<note>-20s %<rate_of_return>10s",
        values
      )
    end

    def print_simulation_evaluation
      puts DASH_SEPARATOR
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

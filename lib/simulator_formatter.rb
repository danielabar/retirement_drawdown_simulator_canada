# frozen_string_literal: true

class SimulatorFormatter
  def initialize(simulation_results)
    @results = simulation_results
  end

  def print_all
    print_summary
    print_header
    print_yearly_results
  end

  private

  def format_summary(summary)
    {
      desired_income: format_currency(summary[:desired_income]),
      rrsp_withholding_tax: format_currency(summary[:rrsp_withholding_tax]),
      expected_refund: format_currency(summary[:expected_refund]),
      rrsp_available_after_tax: format_currency(summary[:rrsp_available_after_tax]),
      amount_available_subsequent_years: format_currency(summary[:amount_available_subsequent_years])
    }
  end

  def print_summary
    summary = @results.find { |r| r[:type] == :summary }
    formatted_summary = format_summary(summary)

    puts "=== Retirement Plan Summary ==="
    puts "Desired Income Including TFSA Contribution: #{formatted_summary[:desired_income]}"
    puts "RRSP Withholding Tax: #{formatted_summary[:rrsp_withholding_tax]}"
    puts "Expected Refund: #{formatted_summary[:expected_refund]}"
    puts "RRSP Available After Tax: #{formatted_summary[:rrsp_available_after_tax]}"
    puts "Amount Available in Subsequent Years: #{formatted_summary[:amount_available_subsequent_years]}"
    puts "-" * 90
  end

  def print_header
    puts format("%<age>-10s %<rrsp>-20s %<tfsa>-20s %<taxable>-20s %<note>-20s",
                age: "Age", rrsp: "RRSP", tfsa: "TFSA", taxable: "Taxable", note: "Note")
    puts "-" * 90
  end

  def print_yearly_results
    @results.each do |record|
      next unless record[:type] == :yearly_status

      puts format("%<age>-10d %<rrsp>-20s %<tfsa>-20s %<taxable>-20s %<note>-20s",
                  age: record[:age], rrsp: format_currency(record[:rrsp_balance]),
                  tfsa: format_currency(record[:tfsa_balance]), taxable: format_currency(record[:taxable_balance]),
                  note: record[:note])
    end
  end

  def format_currency(amount)
    "$#{format('%.2f', amount).reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
  end
end

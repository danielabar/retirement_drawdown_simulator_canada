# frozen_string_literal: true

class SimulatorFormatter
  def initialize(simulation_results, first_year_cash_flow_results)
    @results = simulation_results
    @first_year_cash_flow_results = first_year_cash_flow_results
  end

  def print_all
    print_first_year_cash_flow
    print_header
    print_yearly_results
  end

  private

  def print_first_year_cash_flow
    puts "=== First-Year Cash Flow Breakdown ==="
    @first_year_cash_flow_results.each do |label, value|
      puts "#{label}: #{format_currency(value)}"
    end
    puts "-" * 110
  end

  def print_header
    puts format("%<age>-10s %<rrsp>-20s %<tfsa>-20s %<taxable>-20s %<note>-20s %<rate_of_return>10s",
                age: "Age", rrsp: "RRSP", tfsa: "TFSA", taxable: "Taxable", note: "Note", rate_of_return: "RoR")

    puts "-" * 110
  end

  # TODO: They're all of type yearly_status now, maybe no longer need that check
  def print_yearly_results
    @results.each do |record|
      next unless record[:type] == :yearly_status

      puts format("%<age>-10d %<rrsp>-20s %<tfsa>-20s %<taxable>-20s %<note>-20s %<rate_of_return>10s",
                  age: record[:age],
                  rrsp: format_currency(record[:rrsp_balance]),
                  tfsa: format_currency(record[:tfsa_balance]),
                  taxable: format_currency(record[:taxable_balance]),
                  note: record[:note],
                  rate_of_return: "#{(record[:rate_of_return] * 100).round(2)}%")
    end
  end

  # TODO: Should there be a formatter class for this and rate_of_return formatting?
  def format_currency(amount)
    "$#{format('%.2f', amount).reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
  end
end

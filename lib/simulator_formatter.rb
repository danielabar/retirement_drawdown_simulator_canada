# frozen_string_literal: true

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
      puts "#{label}: #{format_currency(value)}"
    end
    puts "-" * 130
  end

  def print_header
    puts formatted_header
    puts "-" * 130
  end

  def formatted_header
    format(
      "%<age>-10s %<rrsp>-20s %<tfsa>-20s %<taxable>-20s %<total_balance>-20s %<note>-20s %<rate_of_return>10s",
      age: "Age",
      rrsp: "RRSP",
      tfsa: "TFSA",
      taxable: "Taxable",
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
    format(
      "%<age>-10d %<rrsp>-20s %<tfsa>-20s %<taxable>-20s %<total_balance>-20s %<note>-20s %<rate_of_return>10s",
      age: record[:age],
      rrsp: format_currency(record[:rrsp_balance]),
      tfsa: format_currency(record[:tfsa_balance]),
      taxable: format_currency(record[:taxable_balance]),
      total_balance: format_currency(record[:total_balance]), # Display the total balance
      note: record[:note],
      rate_of_return: "#{(record[:rate_of_return] * 100).round(2)}%"
    )
  end

  def print_simulation_evaluation
    puts "-" * 130
    puts "Simulation Result: #{@evaluator_results[:success] ? 'Success' : 'Failure'}"
    puts @evaluator_results[:explanation]
  end

  # TODO: Should there be a formatter class for this and rate_of_return formatting?
  def format_currency(amount)
    "$#{format('%.2f', amount).reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
  end
end

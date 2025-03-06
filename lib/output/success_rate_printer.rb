# frozen_string_literal: true

module Output
  class SuccessRatePrinter
    def initialize(results)
      @results = results
    end

    def print_summary
      puts "\nSimulation Results:"
      puts "Success Rate: #{format_percentage(results.success_rate)}"
      puts "Average Final Balance: #{format_currency(results.average_final_balance)}"
      puts "Withdrawal Rate: #{format_percentage(results.withdrawal_rate)}"

      print_percentiles
    end

    private

    attr_reader :results

    def print_percentiles
      percentiles = results.percentiles
      puts "\nFinal Balance Percentiles:"
      puts "  10th Percentile: #{format_currency(percentiles[:p10])}"
      puts "  25th Percentile: #{format_currency(percentiles[:p25])}"
      puts "  50th Percentile (Median): #{format_currency(percentiles[:median])}"
      puts "  75th Percentile: #{format_currency(percentiles[:p75])}"
      puts "  90th Percentile: #{format_currency(percentiles[:p90])}"
    end

    def format_percentage(value)
      "#{value.round(2)}%"
    end

    def format_currency(value)
      "$#{value.round(2)}"
    end
  end
end

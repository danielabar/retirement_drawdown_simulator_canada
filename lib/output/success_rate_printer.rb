# frozen_string_literal: true

module Output
  class SuccessRatePrinter
    # Initialized with a populated instance of SuccessRateResults
    def initialize(results)
      @results = results
    end

    def print_summary
      puts "=== Simulation Results ==="
      print_summary_section
      print_percentiles_section
      print_annuity_skip_section
    end

    private

    attr_reader :results

    def print_summary_section
      data = [
        ["Withdrawal Rate", format_percentage(results.withdrawal_rate)],
        ["Success Rate", format_percentage(results.success_rate)],
        ["Average Final Balance", format_currency(results.average_final_balance)]
      ]
      print_table("Summary", data)
    end

    def print_percentiles_section
      data = build_percentiles_data(results.percentiles)
      print_table("Final Balance Percentiles", data)
    end

    def build_percentiles_data(percentiles)
      [
        ["5th Percentile", format_currency(percentiles[:p5])],
        ["10th Percentile", format_currency(percentiles[:p10])],
        ["25th Percentile", format_currency(percentiles[:p25])],
        ["50th Percentile (Median)", format_currency(percentiles[:p50])],
        ["75th Percentile", format_currency(percentiles[:p75])],
        ["90th Percentile", format_currency(percentiles[:p90])],
        ["95th Percentile", format_currency(percentiles[:p95])]
      ]
    end

    def print_table(title, data)
      table = TTY::Table.new(%w[Description Amount], data)
      puts "\n#{title}:"
      puts table.render(:unicode, alignment: %i[left right], padding: [0, 1, 0, 1])
    end

    def print_annuity_skip_section
      return unless results.annuity_skip_count.positive?

      skip_count = results.annuity_skip_count
      total = results.total_runs
      percentage = format_percentage(skip_count.to_f / total)
      puts "\n\u26a0\ufe0f  Annuity purchase skipped in #{skip_count} of #{total} runs (#{percentage}) " \
           "\u2014 RRSP balance was insufficient at purchase age."
    end

    def format_percentage(value)
      NumericFormatter.format_percentage(value)
    end

    def format_currency(value)
      NumericFormatter.format_currency(value)
    end
  end
end

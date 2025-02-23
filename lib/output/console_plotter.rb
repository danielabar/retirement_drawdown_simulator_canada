# frozen_string_literal: true

module Output
  # color is a symbol from UnicodePlot::StyledPrinter::COLOR_ENCODE
  class ConsolePlotter
    def self.plot_return_sequence(ages, rate_of_return)
      plot = UnicodePlot.lineplot(
        ages,
        rate_of_return,
        name: "Return Sequence",
        width: 60,
        height: 10,
        color: :magenta,
        labels: true,
        xlabel: "Age",
        ylabel: "Rate of Return"
      )

      plot.render
    end

    def self.plot_total_balance(ages, total_balances)
      plot = UnicodePlot.lineplot(
        ages,
        total_balances,
        name: "Total Balance Over Time",
        width: 60,
        height: 10,
        color: :cyan,
        labels: true,
        xlabel: "Age",
        ylabel: "Total Balance"
      )
      plot.render
    end
  end
end

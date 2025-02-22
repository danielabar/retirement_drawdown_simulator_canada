# frozen_string_literal: true

module Output
  class ConsolePlotter
    def self.plot(sequence_of_returns)
      ages, returns = sequence_of_returns.transpose
      # color is a symbol from UnicodePlot::StyledPrinter::COLOR_ENCODE
      plot = UnicodePlot.lineplot(
        ages,
        returns,
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

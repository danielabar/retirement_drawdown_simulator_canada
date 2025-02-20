# frozen_string_literal: true

# TODO: 22 move to different namespace as per multiple output types future
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
end

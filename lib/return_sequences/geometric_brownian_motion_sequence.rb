# frozen_string_literal: true

module ReturnSequences
  # Generates a sequence of annual portfolio returns using Geometric Brownian Motion (GBM).
  #
  # == The problem GBM solves
  #
  # A simple retirement simulator might assume your portfolio grows by a steady 5% every
  # year. That produces clean, predictable charts — but it's not how markets actually work.
  # Real markets lurch up and down: a great year, two bad years, another great year. The
  # *order* of those ups and downs matters enormously in retirement, because you're selling
  # investments to fund spending at the same time. A crash in year 2 of retirement is far
  # more damaging than the same crash in year 20.
  #
  # GBM is a way of generating realistic-looking sequences of annual returns: mostly near
  # the long-run average, but with genuine good years and bad years, including occasional
  # severe crashes. Unlike using actual historical return data, GBM can produce sequences
  # that have never happened before — useful for stress-testing a plan against futures
  # worse than any we've seen.
  #
  # == Known limitation: no mean reversion
  #
  # Real markets tend to recover after crashes — cheap prices attract buyers, pushing
  # returns back up. GBM does not model this. Every year is drawn independently, so
  # the model can generate long strings of bad years with no corrective pull.
  # This means GBM will produce lower success rates than historical studies (e.g.
  # the "4% rule" research) for the same withdrawal rate, even with well-calibrated
  # parameters. That is a deliberate trade-off: the goal is stress-testing against
  # a future that could be worse than history, not reproducing historical outcomes.
  #
  # == How it works
  #
  # Each simulated year gets: long-run average return + a random shock.
  # Most shocks are small; occasionally they're large (in either direction).
  # The shocks are drawn from a Student-t distribution, which produces extreme years
  # more often than a simple bell curve would — better matching how real markets behave.
  #
  # == Plain-English references
  # - https://medium.com/the-quant-journey/a-gentle-introduction-to-geometric-brownian-motion-in-finance-68c37ba6f828
  # - https://www.quantstart.com/articles/Geometric-Brownian-Motion/
  class GeometricBrownianMotionSequence < ReturnSequences::BaseSequence
    # Controls how often extreme years occur in the simulation.
    #
    # Lower values = more frequent crashes and booms; higher values = closer to a
    # normal bell curve where extreme years are rare.
    #
    # Why 10? Two competing concerns:
    # - We want extreme years to be more common than a pure bell curve predicts,
    #   because real markets do crash more often than the bell curve would suggest.
    # - But we don't want to be so extreme that the simulation becomes incredible.
    #   At df=5, a 2.58% withdrawal rate (considered ultra-conservative) showed only
    #   80% success — implying 1-in-5 retirees would fail at that rate, which no
    #   historical data supports.
    #
    # df=10 is a middle ground: crashes and booms happen a bit more often than a
    # normal bell curve, but not so often that the results feel detached from reality.
    # It also means the simulation can generate scenarios slightly worse than anything
    # in the historical record — which is the whole point of using this approach rather
    # than just replaying past data.
    #
    # See: https://en.wikipedia.org/wiki/Student%27s_t-distribution
    DEGREES_OF_FREEDOM = 10

    protected

    # For each year between start_age and max_age, draws a random shock (z) from a
    # Student-t distribution and applies the GBM formula to produce an annual return.
    #
    # Key terms:
    # - drift:  the average annual return converted to log-return form (e.g. 5% → log(1.05) ≈ 0.0488),
    #           required because the formula works in log space.
    # - sigma:  volatility — how wide the spread of annual returns is; higher = wilder swings.
    # - z:      the random shock for the year (e.g. -1.3 or +0.8), representing how far
    #           this particular year deviates from the average.
    # - -(0.5 * sigma²): the Ito correction — without it, compounding maths would cause the
    #           average of many simulated runs to drift above the intended average.
    def generate_returns
      sequence = {}
      drift    = Math.log(1 + @avg)
      sigma    = compute_sigma

      (@start_age..@max_age).each do |age|
        z = rand_student_t(degrees_of_freedom: DEGREES_OF_FREEDOM)
        r = Math.exp(drift - (0.5 * (sigma**2)) + (sigma * z)) - 1
        sequence[age] = r.round(4)
      end

      sequence
    end

    private

    # Derives sigma (volatility) from the user's min/max inputs.
    # Uses the statistical rule that ~99.7% of observations fall within
    # ±3 standard deviations of the mean (the "three-sigma rule").
    # The asymmetric max() picks whichever tail is wider, so an investment
    # with a more extreme downside than upside (or vice versa) is handled correctly.
    # For realistic results, min/max should represent the historical extreme annual
    # returns for your investment type — not a comfortable or typical range.
    def compute_sigma
      deviation = [@max - @avg, @avg - @min].max
      deviation / 3.0
    end

    # Generates a single random number from a standard normal distribution
    # (bell curve centred at 0 with standard deviation 1) using the Box-Muller transform,
    # which converts two uniform random numbers into a normally distributed one.
    # See: https://en.wikipedia.org/wiki/Box%E2%80%93Muller_transform
    def rand_normal(mean = 0.0, stddev = 1.0)
      u1 = rand
      u2 = rand
      z0 = Math.sqrt(-2.0 * Math.log(u1)) * Math.cos(2 * Math::PI * u2)
      mean + (stddev * z0)
    end

    # Generates a single random number from a Student-t distribution.
    #
    # Why Student-t instead of normal? Real annual market returns have "fat tails" —
    # extreme years (a -37% crash, a +50% boom) happen more often than a normal
    # distribution would predict. If stock returns were truly normal, a crash as bad
    # as 2008 would be expected roughly once every 10,000 years. In reality, we've
    # seen many such events in the past century.
    #
    # Student-t has the same symmetric bell shape as normal, but with heavier tails:
    # the lower the degrees_of_freedom, the more often extreme values occur.
    # df=5 is commonly cited for *daily* stock returns, but annual returns are much
    # closer to normal — using df=5 for annual data overcorrects significantly.
    # df=10 produces mild fat tails appropriate for annual return modelling.
    #
    # Formula: t = Z / sqrt(V / df), where Z is a standard normal draw and
    # V is a chi-squared draw (the sum of df squared standard normals).
    def rand_student_t(degrees_of_freedom:)
      z = rand_normal
      v = Array.new(degrees_of_freedom) { rand_normal**2 }.sum
      z / Math.sqrt(v / degrees_of_freedom)
    end
  end
end

# frozen_string_literal: true

# Unused for now
class ReturnSequenceComplicated
  attr_reader :returns

  def initialize(start_age, max_age, avg, min, max)
    @start_age = start_age
    @max_age   = max_age
    @avg       = avg
    @min       = min
    @max       = max
    @returns   = nil
  end

  def get_return_for_age(age)
    @returns ||= generate_returns
    @returns[age] || @avg
  end

  private

  # Choose the simulation method based on whether there's variability.
  def generate_returns
    return constant_returns if no_variability?

    variable_returns
  end

  # When all inputs are the same, return a constant sequence.
  def no_variability?
    @avg == @min && @min == @max
  end

  def constant_returns
    (@start_age..@max_age).to_h { |age| [age, @avg] }
  end

  # Generates a sequence of annual returns using a geometric Brownian motion model.
  #
  # The GBM model here computes the return for each year as:
  #
  #   r = exp(drift - 0.5 * σ² + σ * Z) - 1
  #
  # where:
  #   - drift = ln(1 + @avg) is chosen so that the expected return is roughly @avg,
  #   - σ is an estimate of volatility,
  #   - Z is a standard normal random variable.
  def variable_returns
    sequence = {}
    drift    = Math.log(1 + @avg)
    sigma    = compute_sigma

    (@start_age..@max_age).each do |age|
      z = rand_normal
      # Compute the annual return using the GBM formula.
      r = Math.exp(drift - (0.5 * (sigma**2)) + (sigma * z)) - 1
      sequence[age] = r
    end

    sequence
  end

  # Estimate the volatility (σ) based on the provided min and max.
  # This heuristic assumes that about 99.7% of outcomes (±3σ) fall within the given range.
  def compute_sigma
    deviation = [@max - @avg, @avg - @min].max
    deviation / 3.0
  end

  # Generates a normally distributed random number with the given mean and standard deviation
  # using the Box–Muller transform.
  def rand_normal(mean = 0.0, stddev = 1.0)
    u1 = rand
    u2 = rand
    z0 = Math.sqrt(-2.0 * Math.log(u1)) * Math.cos(2 * Math::PI * u2)
    mean + (stddev * z0)
  end
end

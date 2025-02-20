# frozen_string_literal: true

module ReturnSequences
  # Generate a sequence of returns for ages between `@start_age` and `@max_age`
  # using a Geometric Brownian Motion (GBM) model.
  # Returns are calculated based on a drift term (`@avg`),
  # and a volatility term (`sigma`), with random shocks (`z`) introduced at each age.
  # The resulting sequence is returned as a hash with age as the key and return as the value.
  class GeometricBrownianMotionSequence < ReturnSequences::BaseSequence
    # TODO: 22 - test for getting specific age vs getting all
    # just verify that value is between min and max
    # TODO: 22 - this logic is actually the same for all of them
    # should it be in the base class? And then subclasses are only
    # required to implement generate_returns which could be protected instead of private
    def get_return_for_age(age = nil)
      @returns ||= generate_returns
      return @returns.sort.to_a if age.nil?

      @returns[age] || @avg
    end

    private

    def generate_returns
      sequence = {}
      drift    = Math.log(1 + @avg)
      sigma    = compute_sigma

      (@start_age..@max_age).each do |age|
        z = rand_normal
        r = Math.exp(drift - (0.5 * (sigma**2)) + (sigma * z)) - 1
        sequence[age] = r
      end

      sequence
    end

    def compute_sigma
      deviation = [@max - @avg, @avg - @min].max
      deviation / 3.0
    end

    def rand_normal(mean = 0.0, stddev = 1.0)
      u1 = rand
      u2 = rand
      z0 = Math.sqrt(-2.0 * Math.log(u1)) * Math.cos(2 * Math::PI * u2)
      mean + (stddev * z0)
    end
  end
end

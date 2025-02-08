# frozen_string_literal: true

module ReturnSequences
  class GeometricBrownianMotionSequence < ReturnSequences::BaseSequence
    def get_return_for_age(age)
      @returns ||= generate_returns
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

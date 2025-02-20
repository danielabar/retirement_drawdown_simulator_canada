# frozen_string_literal: true

module ReturnSequences
  class MeanReturnSequence < ReturnSequences::BaseSequence
    MAX_LOOP_ATTEMPTS = 1000

    def get_return_for_age(age = nil)
      @returns ||= generate_returns
      return @returns.sort.to_a if age.nil?

      @returns[age] || @avg
    end

    private

    def generate_returns
      count = @max_age - @start_age + 1
      attempts = 0

      loop do
        attempts += 1
        returns = generate_random_returns(count)
        adjusted_returns = adjust_returns_to_average(returns, @avg)

        return build_return_sequence(adjusted_returns) if all_returns_valid?(adjusted_returns)

        raise_max_attempts_error if attempts >= MAX_LOOP_ATTEMPTS
      end
    end

    def generate_random_returns(count)
      Array.new(count) { Kernel.rand(@min..@max) }
    end

    def adjust_returns_to_average(returns, target_avg)
      current_avg = returns.sum.to_f / returns.size
      adjustment = target_avg - current_avg

      # Apply the adjustment evenly to all returns
      returns.map { |r| r + adjustment }
    end

    def all_returns_valid?(returns)
      returns.all? { |r| r.between?(@min, @max) }
    end

    def build_return_sequence(returns)
      (@start_age..@max_age).zip(returns).to_h
    end

    def raise_max_attempts_error
      raise "Unable to generate a return sequence after #{MAX_LOOP_ATTEMPTS} attempts"
    end
  end
end

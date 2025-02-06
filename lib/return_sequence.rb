# frozen_string_literal: true

class ReturnSequence
  def initialize(start_age, max_age, avg, min, max)
    @start_age = start_age
    @max_age = max_age
    @avg = avg
    @min = min
    @max = max
    @returns = nil
  end

  def get_return_for_age(age)
    @returns ||= generate_returns
    # temp debug
    # puts "=== RETURN FOR AGE #{age} : #{@returns[age] || @avg} ==="
    @returns[age] || @avg
  end

  private

  def generate_returns
    return constant_returns if no_variability?

    variable_returns
  end

  def no_variability?
    @avg == @min && @min == @max
  end

  def constant_returns
    (@start_age..@max_age).to_h { |age| [age, @avg] }
  end

  def variable_returns
    count = @max_age - @start_age + 1

    loop do
      returns = generate_random_returns(count - 1)
      final_return = calculate_final_return(returns, count)

      return build_return_sequence(returns, final_return) if valid_return?(final_return)
    end
  end

  def generate_random_returns(count)
    Array.new(count) { rand(@min..@max) }
  end

  def calculate_final_return(returns, count)
    required_sum = @avg * count
    current_sum = returns.sum
    required_sum - current_sum
  end

  def valid_return?(final_return)
    final_return.between?(@min, @max)
  end

  def build_return_sequence(returns, final_return)
    full_returns = returns + [final_return]
    (@start_age..@max_age).zip(full_returns).to_h
  end
end

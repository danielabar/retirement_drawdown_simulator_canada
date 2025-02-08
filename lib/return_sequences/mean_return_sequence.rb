# frozen_string_literal: true

module ReturnSequences
  class MeanReturnSequence < ReturnSequences::BaseSequence
    def get_return_for_age(age)
      @returns ||= generate_returns
      @returns[age] || @avg
    end

    private

    def generate_returns
      return constant_returns if @avg == @min && @min == @max

      variable_returns
    end

    def constant_returns
      (@start_age..@max_age).to_h { |age| [age, @avg] }
    end

    def variable_returns
      (@start_age..@max_age).to_h { |age| [age, rand(@min..@max)] }
    end
  end
end

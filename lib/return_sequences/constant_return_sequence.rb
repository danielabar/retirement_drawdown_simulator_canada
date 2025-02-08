# frozen_string_literal: true

module ReturnSequences
  class ConstantReturnSequence < ReturnSequences::BaseSequence
    def get_return_for_age(age)
      @returns ||= generate_returns
      @returns[age] || @avg
    end

    private

    def generate_returns
      constant_returns
    end

    def constant_returns
      (@start_age..@max_age).to_h { |age| [age, @avg] }
    end
  end
end

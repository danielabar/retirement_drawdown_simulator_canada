# frozen_string_literal: true

module ReturnSequences
  class ConstantReturnSequence < ReturnSequences::BaseSequence
    protected

    def generate_returns
      constant_returns
    end

    private

    def constant_returns
      (@start_age..@max_age).to_h { |age| [age, @avg] }
    end
  end
end

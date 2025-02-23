# frozen_string_literal: true

module ReturnSequences
  class BaseSequence
    def initialize(start_age, max_age, avg, min, max)
      @start_age = start_age
      @max_age = max_age
      @avg = avg
      @min = min
      @max = max
    end

    def get_return_for_age(age = nil)
      @returns ||= generate_returns
      return @returns.sort.to_a if age.nil?

      @returns[age] || @avg
    end

    protected

    def generate_returns
      raise NotImplementedError, "Subclasses must implement `generate_returns` method"
    end
  end
end

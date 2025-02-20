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
      raise NotImplementedError, "Subclasses must implement this method"
    end
  end
end

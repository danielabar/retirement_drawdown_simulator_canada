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

    # Exposes the materialized {age => return} map. Used by `success_rate`
    # mode to persist failed sequences to disk (see `FailedRuns::Writer`),
    # and by `Simulator#build_results` to surface the sequence alongside
    # yearly results. Forces generation on first call (same lazy `||=`
    # pattern as `get_return_for_age`), and returns a copy so callers can't
    # mutate the sequence's internal state.
    def returns_by_age
      @returns ||= generate_returns
      @returns.dup
    end

    protected

    def generate_returns
      raise NotImplementedError, "Subclasses must implement `generate_returns` method"
    end
  end
end

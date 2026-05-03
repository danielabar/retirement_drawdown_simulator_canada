# frozen_string_literal: true

module ReturnSequences
  # Loads a previously-saved {age => return} sequence from a YAML file rather
  # than generating one. Used in `detailed` mode to replay a captured failure
  # produced by `success_rate` mode.
  class RecordedSequence < ReturnSequences::BaseSequence
    REQUIRED_KEY = "return_sequence"

    attr_reader :file_path

    # `start_age` and `max_age` must be the same bounds the simulator will
    # iterate over — i.e. `AppConfig#retirement_age` and `AppConfig#max_age`.
    # In production this is enforced structurally: `SequenceSelector` builds
    # both this object and the `Simulator` from the same `AppConfig`, so
    # they share a single source of truth. `validate_range_coverage!`
    # depends on that contract — it checks the file against these args
    # rather than asking the simulator directly.
    def initialize(start_age, max_age, file_path)
      super(start_age, max_age, nil, nil, nil)
      @file_path = file_path
      @payload = load_payload
      validate_range_coverage!
    end

    def summary
      payload.dig("outcome", "summary")
    end

    def inputs_digest
      payload["inputs_digest"]
    end

    protected

    def generate_returns
      raw = payload[REQUIRED_KEY]
      raw.each_with_object({}) { |(age, ret), h| h[Integer(age)] = Float(ret) }
    end

    private

    attr_reader :payload

    def load_payload
      raise "Recorded sequence file not found: #{@file_path}" unless File.exist?(@file_path)

      data = YAML.load_file(@file_path, permitted_classes: [Time, Date, Symbol])
      unless data.is_a?(Hash) && data.key?(REQUIRED_KEY) && data[REQUIRED_KEY].is_a?(Hash)
        raise "Recorded sequence file #{@file_path} is malformed: missing or invalid '#{REQUIRED_KEY}' map"
      end

      data
    end

    # Ensures the recorded file has a return entry for every age the simulator
    # will ask about. The simulator iterates `(start_age..max_age)` and looks
    # up each age in the loaded map; without this check, an uncovered age
    # would fall through to `BaseSequence#get_return_for_age`'s `@returns[age]
    # || @avg` fallback. RecordedSequence has no average to fall back on (it
    # passes `nil` for `avg` to `super`), so the simulator would receive a
    # `nil` market return and crash several frames later in
    # `Strategy::RrspToTaxableToTfsa#withdraw_from_cash_cushion?` with a
    # confusing `NoMethodError: undefined method '<' for nil`. Failing here
    # instead surfaces the real cause — a mismatch between the captured
    # range and the requested range — at construction time, before any
    # simulation runs.
    #
    # Coverage rule: the file's recorded ages must span at least
    # `start_age..max_age`. The file may extend further on either side
    # without issue (extra entries are just unused lookups), but it must
    # not be missing either end of the requested range.
    def validate_range_coverage!
      ages = @payload[REQUIRED_KEY].keys.map { |k| Integer(k) }
      file_min, file_max = ages.minmax
      return if @start_age >= file_min && @max_age <= file_max

      raise <<~MSG
        Recorded sequence file does not cover the requested age range.
          File:      #{@file_path}
          Requested: ages #{@start_age}..#{@max_age}
          Covered:   ages #{file_min}..#{file_max}
        Fix: raise retirement_age to #{file_min} (or higher) and lower max_age to #{file_max} (or lower) in inputs.yml,
        or point recorded_sequence_file at a capture covering #{@start_age}..#{@max_age}.
      MSG
    end
  end
end

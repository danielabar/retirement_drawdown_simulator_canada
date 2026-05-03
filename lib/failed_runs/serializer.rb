# frozen_string_literal: true

module FailedRuns
  # Reads and writes the YAML schema for a single saved failed run.
  #
  # Schema:
  #   id: run_NNNN
  #   captured_at: <ISO8601 timestamp>
  #   inputs_digest: <sha256 hex>
  #   outcome:
  #     success: false
  #     summary: "ran out at age 84, final balance $0"
  #     final_age: 84
  #     final_balance: 0
  #     withdrawal_rate: 0.04
  #   return_sequence:
  #     65: 0.0623
  #     ...
  class Serializer
    PERMITTED_CLASSES = [Time, Date, Symbol].freeze

    def self.write(path, payload)
      File.write(path, payload.to_yaml)
    end

    def self.read(path)
      YAML.load_file(path, permitted_classes: PERMITTED_CLASSES)
    end
  end
end

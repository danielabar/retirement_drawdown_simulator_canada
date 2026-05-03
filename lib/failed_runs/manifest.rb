# frozen_string_literal: true

module FailedRuns
  # Writes a human-readable index.md alongside saved failure YAML files,
  # listing each saved run with a one-line summary.
  class Manifest
    FILENAME = "index.md"

    def self.write(dir, entries, captured_at: Time.now.utc, inputs_digest: nil)
      lines = ["# Failed runs from success_rate mode", ""]
      lines << "Captured: #{captured_at.iso8601}"
      lines << "Source inputs digest: #{inputs_digest}" if inputs_digest
      lines << ""
      sorted = entries.sort_by { |e| e[:filename] }
      sorted.each do |entry|
        lines << "- #{entry[:filename]} — #{entry[:summary]}"
      end
      lines << ""
      File.write(File.join(dir, FILENAME), lines.join("\n"))
    end
  end
end

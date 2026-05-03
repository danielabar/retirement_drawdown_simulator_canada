# frozen_string_literal: true

require "tempfile"
require_relative "../../spec_helper"

RSpec.describe FailedRuns::Serializer do
  let(:payload) do
    {
      "id" => "run_0001",
      "captured_at" => Time.utc(2026, 5, 2, 14, 30, 0),
      "inputs_digest" => "abc123",
      "outcome" => {
        "success" => false,
        "summary" => "ran out at age 84, final balance $0",
        "final_age" => 84,
        "final_balance" => 0,
        "withdrawal_rate" => 0.04
      },
      "return_sequence" => { 65 => 0.0623, 66 => -0.2845 }
    }
  end

  it "round-trips through write and read" do
    Tempfile.create(["run", ".yml"]) do |f|
      f.close
      described_class.write(f.path, payload)
      expect(described_class.read(f.path)).to eq(payload)
    end
  end

  it "writes valid YAML at the documented schema's top-level keys" do
    Tempfile.create(["run", ".yml"]) do |f|
      f.close
      described_class.write(f.path, payload)
      loaded = described_class.read(f.path)
      expect(loaded.keys).to include("id", "captured_at", "inputs_digest", "outcome", "return_sequence")
      expect(loaded["outcome"].keys).to include("success", "summary", "final_age", "final_balance", "withdrawal_rate")
    end
  end
end

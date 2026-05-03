# frozen_string_literal: true

require "tempfile"
require_relative "../../spec_helper"

RSpec.describe ReturnSequences::RecordedSequence do
  subject(:sequence) { described_class.new(65, 69, sample_path) }

  let(:base_fixture_path) { File.expand_path("../../fixtures", __dir__) }
  let(:sample_path) { File.join(base_fixture_path, "recorded_runs", "sample.yml") }

  describe "#returns_by_age" do
    it "returns the stored map keyed by integer ages with float values" do
      expect(sequence.returns_by_age).to eq(
        65 => 0.05,
        66 => -0.30,
        67 => -0.20,
        68 => 0.02,
        69 => 0.04
      )
    end
  end

  describe "#get_return_for_age" do
    it "returns the stored return for each age" do
      expect(sequence.get_return_for_age(65)).to eq(0.05)
      expect(sequence.get_return_for_age(66)).to eq(-0.30)
    end
  end

  describe "#file_path" do
    it "exposes the source file path" do
      expect(sequence.file_path).to eq(sample_path)
    end
  end

  describe "#summary" do
    it "exposes the saved outcome summary" do
      expect(sequence.summary).to eq("ran out at age 67, final balance $0")
    end
  end

  describe "#inputs_digest" do
    it "exposes the saved inputs digest" do
      expect(sequence.inputs_digest).to eq("deadbeef")
    end
  end

  describe "range coverage validation" do
    # The fixture covers ages 65..69. A request for a wider range cannot be
    # served, since the missing ages would silently fall through to the
    # superclass's @avg (nil for RecordedSequence) and crash deep in the
    # withdrawal strategy with a confusing NilClass comparison error.
    it "raises a clear error when start_age is below the file's min recorded age" do
      expect do
        described_class.new(60, 69, sample_path)
      end.to raise_error(/does not cover/i)
    end

    it "raises a clear error when max_age is above the file's max recorded age" do
      expect do
        described_class.new(65, 75, sample_path)
      end.to raise_error(/does not cover/i)
    end
  end

  describe "missing or malformed file" do
    it "raises when file is missing" do
      expect do
        described_class.new(65, 69, "/nonexistent/path.yml")
      end.to raise_error(/not found/)
    end

    it "raises when file is missing the return_sequence key" do
      Tempfile.create(["malformed", ".yml"]) do |f|
        f.write({ "id" => "x" }.to_yaml)
        f.close
        expect do
          described_class.new(65, 69, f.path)
        end.to raise_error(/malformed/)
      end
    end
  end
end

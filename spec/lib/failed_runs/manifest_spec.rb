# frozen_string_literal: true

require "tmpdir"
require_relative "../../spec_helper"

RSpec.describe FailedRuns::Manifest do
  let(:entries) do
    [
      { filename: "run_0002.yml", summary: "reached 95 with $12,400 (below 40k threshold)" },
      { filename: "run_0001.yml", summary: "ran out at age 79, final balance $0" }
    ]
  end

  def write_in_tmp(&)
    Dir.mktmpdir do |dir|
      described_class.write(dir, entries,
                            captured_at: Time.utc(2026, 5, 2, 14, 30, 0),
                            inputs_digest: "abc123")
      yield File.read(File.join(dir, "index.md"))
    end
  end

  it "includes the header and metadata block" do
    write_in_tmp do |contents|
      expect(contents).to include("# Failed runs from success_rate mode",
                                  "Captured: 2026-05-02T14:30:00Z",
                                  "Source inputs digest: abc123")
    end
  end

  it "includes one bullet per entry with summary text" do
    write_in_tmp do |contents|
      expect(contents).to include("- run_0001.yml — ran out at age 79, final balance $0",
                                  "- run_0002.yml — reached 95 with $12,400 (below 40k threshold)")
    end
  end

  it "sorts entries by filename ascending" do
    write_in_tmp do |contents|
      expect(contents.index("run_0001.yml")).to be < contents.index("run_0002.yml")
    end
  end
end

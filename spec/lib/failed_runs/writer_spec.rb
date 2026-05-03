# frozen_string_literal: true

require "tmpdir"
require_relative "../../spec_helper"

RSpec.describe FailedRuns::Writer do
  let(:app_config) do
    AppConfig.new(
      "retirement_age" => 65,
      "max_age" => 95,
      "province_code" => "ONT",
      "annual_tfsa_contribution" => 0,
      "desired_spending" => 40_000,
      "success_factor" => 1,
      "annual_growth_rate" => {
        "average" => 0.05, "min" => -0.4, "max" => 0.45,
        "downturn_threshold" => -0.1, "savings" => 0.005
      },
      "accounts" => { "rrsp" => 600_000, "taxable" => 200_000, "tfsa" => 200_000, "cash_cushion" => 0 },
      "cpp" => { "start_age" => 65, "monthly_amount" => 0 },
      "taxes" => { "rrsp_withholding_rate" => 0.3 }
    )
  end

  def fake_failure_output(final_age: 84, final_balance: 0)
    {
      yearly_results: [
        { age: 65, total_balance: 100_000, rate_of_return: 0.05 },
        { age: final_age, total_balance: final_balance, rate_of_return: -0.05 }
      ],
      return_sequence: { 65 => 0.05, final_age => -0.05 }
    }
  end

  def fake_eval(success:, withdrawal_rate: 0.04)
    { success: success, withdrawal_rate: withdrawal_rate }
  end

  describe "#prepare!" do
    it "removes existing run_*.yml and index.md but leaves .gitkeep" do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, ".gitkeep"), "")
        File.write(File.join(dir, "run_9999.yml"), "old")
        File.write(File.join(dir, "index.md"), "old")
        writer = described_class.new(app_config, output_dir: dir)
        writer.prepare!
        expect(File.exist?(File.join(dir, ".gitkeep"))).to be true
        expect(File.exist?(File.join(dir, "run_9999.yml"))).to be false
        expect(File.exist?(File.join(dir, "index.md"))).to be false
      end
    end
  end

  describe "#offer + #flush!" do
    it "writes one file per offered failure when N <= capacity" do
      Dir.mktmpdir do |dir|
        writer = described_class.new(app_config, output_dir: dir, capacity: 50)
        10.times { writer.offer(fake_failure_output, fake_eval(success: false)) }
        writer.flush!
        files = Dir.glob(File.join(dir, "run_*.yml"))
        expect(files.size).to eq(10)
        expect(files.min).to end_with("run_0001.yml")
        expect(files.max).to end_with("run_0010.yml")
        expect(File.exist?(File.join(dir, "index.md"))).to be true
      end
    end

    it "caps at exactly capacity when N > capacity" do
      Dir.mktmpdir do |dir|
        writer = described_class.new(app_config, output_dir: dir, capacity: 50)
        200.times { writer.offer(fake_failure_output, fake_eval(success: false)) }
        writer.flush!
        files = Dir.glob(File.join(dir, "run_*.yml"))
        expect(files.size).to eq(50)
      end
    end

    it "rejects successful runs offered" do
      Dir.mktmpdir do |dir|
        writer = described_class.new(app_config, output_dir: dir)
        5.times { writer.offer(fake_failure_output, fake_eval(success: true)) }
        writer.flush!
        files = Dir.glob(File.join(dir, "run_*.yml"))
        expect(files).to be_empty
      end
    end

    it "writes a manifest whose summaries match each saved run" do
      Dir.mktmpdir do |dir|
        writer = described_class.new(app_config, output_dir: dir)
        writer.offer(fake_failure_output(final_age: 79, final_balance: 0), fake_eval(success: false))
        writer.offer(fake_failure_output(final_age: 95, final_balance: 12_400), fake_eval(success: false))
        writer.flush!
        manifest = File.read(File.join(dir, "index.md"))
        Dir.glob(File.join(dir, "run_*.yml")).each do |path|
          payload = FailedRuns::Serializer.read(path)
          expect(manifest).to include(File.basename(path))
          expect(manifest).to include(payload.dig("outcome", "summary"))
        end
      end
    end

    it "writes each payload with the inputs digest" do
      Dir.mktmpdir do |dir|
        writer = described_class.new(app_config, output_dir: dir)
        writer.offer(fake_failure_output, fake_eval(success: false))
        writer.flush!
        path = Dir.glob(File.join(dir, "run_*.yml")).first
        payload = FailedRuns::Serializer.read(path)
        expect(payload["inputs_digest"]).to eq(InputsDigest.for(app_config))
      end
    end

    it "produces a 'ran out' summary when final_age < max_age" do
      Dir.mktmpdir do |dir|
        writer = described_class.new(app_config, output_dir: dir)
        writer.offer(fake_failure_output(final_age: 79, final_balance: 0), fake_eval(success: false))
        writer.flush!
        path = Dir.glob(File.join(dir, "run_*.yml")).first
        payload = FailedRuns::Serializer.read(path)
        expect(payload.dig("outcome", "summary")).to match(/ran out at age 79/)
      end
    end

    it "produces a 'reached max_age' summary when final_age == max_age but below threshold" do
      Dir.mktmpdir do |dir|
        writer = described_class.new(app_config, output_dir: dir)
        writer.offer(fake_failure_output(final_age: 95, final_balance: 12_000), fake_eval(success: false))
        writer.flush!
        path = Dir.glob(File.join(dir, "run_*.yml")).first
        payload = FailedRuns::Serializer.read(path)
        expect(payload.dig("outcome", "summary")).to match(/reached max_age 95/)
      end
    end
  end
end

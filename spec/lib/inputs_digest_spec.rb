# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe InputsDigest do
  let(:base_inputs) do
    {
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
      "accounts" => { "rrsp" => 600_000, "taxable" => 200_000, "tfsa" => 200_000, "cash_cushion" => 40_000 },
      "cpp" => { "start_age" => 65, "monthly_amount" => 0 },
      "taxes" => { "rrsp_withholding_rate" => 0.3 }
    }
  end

  it "produces the same digest for identical inputs" do
    a = described_class.for(AppConfig.new(base_inputs.dup))
    b = described_class.for(AppConfig.new(base_inputs.dup))
    expect(a).to eq(b)
  end

  it "produces a different digest when desired_spending changes" do
    a = described_class.for(AppConfig.new(base_inputs.dup))
    changed = base_inputs.merge("desired_spending" => 35_000)
    b = described_class.for(AppConfig.new(changed))
    expect(a).not_to eq(b)
  end

  it "ignores mode (excluded from digest)" do
    a = described_class.for(AppConfig.new(base_inputs.merge("mode" => "detailed")))
    b = described_class.for(AppConfig.new(base_inputs.merge("mode" => "success_rate")))
    expect(a).to eq(b)
  end

  it "ignores total_runs (excluded from digest)" do
    a = described_class.for(AppConfig.new(base_inputs.merge("total_runs" => 100)))
    b = described_class.for(AppConfig.new(base_inputs.merge("total_runs" => 1000)))
    expect(a).to eq(b)
  end

  it "ignores return_sequence_type and recorded_sequence_file" do
    a_inputs = base_inputs.merge("return_sequence_type" => "geometric_brownian_motion")
    b_inputs = base_inputs.merge(
      "return_sequence_type" => "recorded",
      "recorded_sequence_file" => "failed_runs/run_0001.yml"
    )
    a = described_class.for(AppConfig.new(a_inputs))
    b = described_class.for(AppConfig.new(b_inputs))
    expect(a).to eq(b)
  end

  it "ignores annual_growth_rate.average/min/max changes" do
    a = described_class.for(AppConfig.new(base_inputs))
    other = base_inputs.deep_dup if base_inputs.respond_to?(:deep_dup)
    other ||= Marshal.load(Marshal.dump(base_inputs))
    other["annual_growth_rate"]["average"] = 0.10
    other["annual_growth_rate"]["min"] = -0.5
    other["annual_growth_rate"]["max"] = 0.5
    b = described_class.for(AppConfig.new(other))
    expect(a).to eq(b)
  end

  it "is sensitive to annual_growth_rate.downturn_threshold" do
    a = described_class.for(AppConfig.new(base_inputs))
    other = Marshal.load(Marshal.dump(base_inputs))
    other["annual_growth_rate"]["downturn_threshold"] = -0.2
    b = described_class.for(AppConfig.new(other))
    expect(a).not_to eq(b)
  end

  it "is insensitive to key ordering in nested hashes" do
    reordered = base_inputs.to_a.reverse.to_h
    reordered["accounts"] = reordered["accounts"].to_a.reverse.to_h
    a = described_class.for(AppConfig.new(base_inputs))
    b = described_class.for(AppConfig.new(reordered))
    expect(a).to eq(b)
  end
end

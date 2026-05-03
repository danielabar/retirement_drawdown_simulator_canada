# frozen_string_literal: true

require "tmpdir"
require_relative "../../spec_helper"

RSpec.describe Run::SuccessRateSimulation do
  let(:base_fixture_path) { File.expand_path("../../fixtures", __dir__) }

  let(:inputs) do
    YAML.load_file(File.join(base_fixture_path, "example_input_low_growth.yml")).merge(
      "mode" => "success_rate",
      "total_runs" => 10,
      "return_sequence_type" => "geometric_brownian_motion",
      # Force the average way down so most runs fail.
      "annual_growth_rate" => {
        "average" => -0.05, "min" => -0.4, "max" => 0.1,
        "downturn_threshold" => -0.5, "savings" => 0.005
      },
      "success_factor" => 1
    )
  end

  let(:app_config) { AppConfig.new(inputs) }

  def run_in_tmp(&)
    Dir.mktmpdir do |dir|
      writer = FailedRuns::Writer.new(app_config, output_dir: dir)
      yield dir, writer
    end
  end

  def silently
    original = $stdout
    $stdout = StringIO.new
    yield
  ensure
    $stdout = original
  end

  it "wipes prior run_*.yml files in prepare!" do
    run_in_tmp do |dir, writer|
      File.write(File.join(dir, "run_9999.yml"), "stale")
      silently { described_class.new(app_config, failed_runs_writer: writer).run }
      expect(File.exist?(File.join(dir, "run_9999.yml"))).to be false
    end
  end

  it "writes captured failure files and a manifest listing them" do
    run_in_tmp do |dir, writer|
      silently { described_class.new(app_config, failed_runs_writer: writer).run }
      files = Dir.glob(File.join(dir, "run_*.yml"))
      manifest = File.read(File.join(dir, "index.md"))
      expect(files).not_to be_empty
      expect(files.size).to be <= 50
      files.each { |path| expect(manifest).to include(File.basename(path)) }
    end
  end

  it "stores the inputs digest in each saved run" do
    run_in_tmp do |dir, writer|
      silently { described_class.new(app_config, failed_runs_writer: writer).run }
      expected = InputsDigest.for(app_config)
      Dir.glob(File.join(dir, "run_*.yml")).each do |path|
        payload = FailedRuns::Serializer.read(path)
        expect(payload["inputs_digest"]).to eq(expected)
      end
    end
  end

  it "saved runs are replayable: detailed mode reproduces the recorded sequence year-by-year" do
    run_in_tmp do |dir, writer|
      silently { described_class.new(app_config, failed_runs_writer: writer).run }
      saved_path = Dir.glob(File.join(dir, "run_*.yml")).first
      saved = FailedRuns::Serializer.read(saved_path)
      replay_inputs = inputs.merge(
        "mode" => "detailed",
        "return_sequence_type" => "recorded",
        "recorded_sequence_file" => saved_path
      )
      replay_config = AppConfig.new(replay_inputs)
      simulator_output = Simulation::Simulator.new(replay_config).run
      simulator_output[:yearly_results].each do |row|
        expect(row[:rate_of_return]).to eq(saved["return_sequence"][row[:age]])
      end
    end
  end
end

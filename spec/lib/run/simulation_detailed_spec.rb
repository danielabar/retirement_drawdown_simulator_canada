# frozen_string_literal: true

require "tempfile"
require "tmpdir"
require_relative "../../spec_helper"

RSpec.describe Run::SimulationDetailed do
  let(:base_fixture_path) { File.expand_path("../../fixtures", __dir__) }

  let(:base_inputs) do
    YAML.load_file(File.join(base_fixture_path, "example_input_low_growth.yml")).merge(
      "mode" => "detailed",
      "max_age" => 69,
      "retirement_age" => 65,
      "success_factor" => 1,
      "annual_growth_rate" => {
        "average" => 0.05, "min" => -0.4, "max" => 0.45,
        "downturn_threshold" => -0.1, "savings" => 0.005
      }
    )
  end

  def write_recorded_run(dir, inputs_digest:, summary: "ran out at age 67, final balance $0")
    payload = {
      "id" => "run_test",
      "captured_at" => Time.utc(2026, 5, 1).iso8601,
      "inputs_digest" => inputs_digest,
      "outcome" => {
        "success" => false, "summary" => summary,
        "final_age" => 67, "final_balance" => 0, "withdrawal_rate" => 0.04
      },
      "return_sequence" => (65..69).each_with_object({}) { |age, h| h[age] = 0.05 }
    }
    path = File.join(dir, "run_test.yml")
    File.write(path, payload.to_yaml)
    path
  end

  it "announces the replayed run with its stored summary on a recorded sequence" do
    Dir.mktmpdir do |dir|
      app_config = AppConfig.new(base_inputs)
      digest = InputsDigest.for(app_config)
      path = write_recorded_run(dir, inputs_digest: digest)
      replay_config = AppConfig.new(base_inputs.merge(
                                      "return_sequence_type" => "recorded",
                                      "recorded_sequence_file" => path
                                    ))
      expect do
        described_class.new(replay_config).run
      end.to output(/Replaying run_test: ran out at age 67, final balance \$0/).to_stdout
    end
  end

  it "warns when stored digest differs from current inputs" do
    Dir.mktmpdir do |dir|
      path = write_recorded_run(dir, inputs_digest: "stale_digest_xyz")
      replay_config = AppConfig.new(base_inputs.merge(
                                      "return_sequence_type" => "recorded",
                                      "recorded_sequence_file" => path
                                    ))
      expect do
        described_class.new(replay_config).run
      end.to output(/inputs.yml has changed since this run was captured/).to_stdout
    end
  end

  it "does not warn when stored digest matches current inputs" do
    Dir.mktmpdir do |dir|
      app_config = AppConfig.new(base_inputs)
      digest = InputsDigest.for(app_config)
      path = write_recorded_run(dir, inputs_digest: digest)
      replay_config = AppConfig.new(base_inputs.merge(
                                      "return_sequence_type" => "recorded",
                                      "recorded_sequence_file" => path
                                    ))
      expect do
        described_class.new(replay_config).run
      end.not_to output(/inputs.yml has changed since this run was captured/).to_stdout
    end
  end
end

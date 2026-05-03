# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe Run::AppConfigValidator do
  def app_config(overrides = {})
    AppConfig.new(overrides)
  end

  describe ".validate!" do
    it "raises when mode: success_rate is combined with return_sequence_type: recorded" do
      config = app_config("return_sequence_type" => "recorded")
      expect do
        described_class.validate!(config, "success_rate")
      end.to raise_error(/recorded.*only valid with.*detailed/m)
    end

    it "does not raise when mode: detailed is combined with return_sequence_type: recorded" do
      config = app_config("return_sequence_type" => "recorded")
      expect { described_class.validate!(config, "detailed") }.not_to raise_error
    end

    it "does not raise on standard generative sequence types in success_rate mode" do
      config = app_config("return_sequence_type" => "geometric_brownian_motion")
      expect { described_class.validate!(config, "success_rate") }.not_to raise_error
    end
  end
end

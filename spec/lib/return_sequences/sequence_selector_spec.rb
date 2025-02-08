# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe ReturnSequences::SequenceSelector do
  let(:base_fixture_path) { File.expand_path("../../fixtures", __dir__) }

  describe "#select" do
    context "when selecting a 'mean' return sequence" do
      let(:app_config) { AppConfig.new(File.join(base_fixture_path, "sequence_mean.yml")) }
      let!(:sequence) { described_class.new(app_config, 65, 100).select }

      it "returns an instance of MeanReturnSequence" do
        expect(sequence).to be_an_instance_of(ReturnSequences::MeanReturnSequence)
      end
    end

    context "when an invalid return sequence type is specified" do
      let(:app_config) { AppConfig.new(File.join(base_fixture_path, "sequence_invalid.yml")) }

      it "raises an error" do
        expect do
          described_class.new(app_config, 65, 100).select
        end.to raise_error("Unknown return_sequence_type: invalid")
      end
    end

    context "when selecting a 'geometric_brownian_motion' return sequence" do
      let(:app_config) { AppConfig.new(File.join(base_fixture_path, "sequence_geometric_brownian_motion.yml")) }
      let!(:sequence) { described_class.new(app_config, 65, 100).select }

      it "returns an instance of GeometricBrownianMotionSequence" do
        expect(sequence).to be_an_instance_of(ReturnSequences::GeometricBrownianMotionSequence)
      end
    end

    context "when selecting a 'constant' return sequence" do
      let(:app_config) { AppConfig.new(File.join(base_fixture_path, "sequence_constant.yml")) }
      let!(:sequence) { described_class.new(app_config, 65, 100).select }

      it "returns an instance of ConstantReturnSequence" do
        expect(sequence).to be_an_instance_of(ReturnSequences::ConstantReturnSequence)
      end
    end
  end
end

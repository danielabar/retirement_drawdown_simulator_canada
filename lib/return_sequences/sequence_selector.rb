# frozen_string_literal: true

module ReturnSequences
  class SequenceSelector
    DEFAULT_RETURN_SEQUENCE_TYPE = "constant"

    def initialize(app_config, retirement_age, max_age)
      @app_config = app_config
      @retirement_age = retirement_age
      @max_age = max_age
    end

    def select
      sequence_type = app_config["return_sequence_type"] || DEFAULT_RETURN_SEQUENCE_TYPE
      case sequence_type
      when "mean" then instantiate_generative(ReturnSequences::MeanReturnSequence)
      when "geometric_brownian_motion" then instantiate_generative(ReturnSequences::GeometricBrownianMotionSequence)
      when "constant" then instantiate_generative(ReturnSequences::ConstantReturnSequence)
      when "recorded" then instantiate_recorded
      else raise "Unknown return_sequence_type: #{sequence_type}"
      end
    end

    private

    attr_reader :app_config, :retirement_age, :max_age

    def instantiate_generative(klass)
      klass.new(retirement_age, max_age, app_config.annual_growth_rate["average"],
                app_config.annual_growth_rate["min"], app_config.annual_growth_rate["max"])
    end

    def instantiate_recorded
      file_path = app_config["recorded_sequence_file"]
      if file_path.nil? || file_path.empty?
        raise "return_sequence_type: recorded requires recorded_sequence_file in inputs"
      end

      ReturnSequences::RecordedSequence.new(retirement_age, max_age, file_path)
    end
  end
end

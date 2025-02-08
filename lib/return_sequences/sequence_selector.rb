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
      klass = case sequence_type
              when "mean" then ReturnSequences::MeanReturnSequence
              when "geometric_brownian_motion" then ReturnSequences::GeometricBrownianMotionSequence
              when "constant" then ReturnSequences::ConstantReturnSequence
              else raise "Unknown return_sequence_type: #{app_config['return_sequence_type']}"
              end

      klass.new(retirement_age, max_age, app_config.annual_growth_rate["average"],
                app_config.annual_growth_rate["min"], app_config.annual_growth_rate["max"])
    end

    private

    attr_reader :app_config, :retirement_age, :max_age
  end
end

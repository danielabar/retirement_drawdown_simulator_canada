# frozen_string_literal: true

require "digest"

# Computes a stable SHA256 digest over the inputs that affect simulation
# outcomes when the return sequence is fixed. Used to flag mismatches when
# replaying a captured failure against edited inputs.
#
# Excludes fields that don't affect outcome on recorded replay: mode,
# total_runs, return_sequence_type, recorded_sequence_file, and the GBM/mean
# parameters (average/min/max) since the sequence comes from disk.
class InputsDigest
  RELEVANT_TOP_LEVEL_KEYS = %w[
    retirement_age
    max_age
    province_code
    success_factor
    desired_spending
    annual_tfsa_contribution
    accounts
    cpp
    oas
    annuity
    taxes
  ].freeze

  RELEVANT_GROWTH_KEYS = %w[downturn_threshold savings].freeze

  def self.for(app_config)
    new(app_config).digest
  end

  def initialize(app_config)
    @app_config = app_config
  end

  def digest
    Digest::SHA256.hexdigest(canonical_yaml)
  end

  private

  def canonical_yaml
    relevant_subset.to_yaml
  end

  def relevant_subset
    subset = {}
    RELEVANT_TOP_LEVEL_KEYS.each do |key|
      subset[key] = sort_deeply(@app_config[key]) if @app_config[key]
    end
    growth = @app_config.annual_growth_rate
    if growth
      growth_subset = RELEVANT_GROWTH_KEYS.each_with_object({}) do |k, h|
        h[k] = growth[k] if growth.key?(k)
      end
      subset["annual_growth_rate"] = growth_subset unless growth_subset.empty?
    end
    sort_deeply(subset)
  end

  def sort_deeply(value)
    case value
    when Hash then value.keys.sort_by(&:to_s).each_with_object({}) { |k, h| h[k] = sort_deeply(value[k]) }
    when Array then value.map { |v| sort_deeply(v) }
    else value
    end
  end
end

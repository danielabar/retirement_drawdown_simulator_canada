# frozen_string_literal: true

class OasConfig
  def initialize
    @config = YAML.load_file(oas_config_file_path)
  end

  def base_monthly_amount(age)
    if age >= 75
      @config["base_monthly_amounts"]["ages_75_plus"]
    else
      @config["base_monthly_amounts"]["ages_65_to_74"]
    end
  end

  def deferral_multiplier(start_age)
    months_deferred = [(start_age - eligible_start_age) * 12, 0].max
    months_deferred = [months_deferred, max_deferral_months].min
    1 + (months_deferred * bonus_per_month)
  end

  def minimum_residency_years
    @config["minimum_residency_years"]
  end

  def full_pension_residency_years
    @config["full_pension_residency_years"]
  end

  def clawback_threshold
    @config["clawback"]["threshold"]
  end

  def clawback_rate
    @config["clawback"]["rate"]
  end

  private

  def eligible_start_age
    @config["deferral"]["eligible_start_age"]
  end

  def maximum_deferral_age
    @config["deferral"]["maximum_deferral_age"]
  end

  def max_deferral_months
    (maximum_deferral_age - eligible_start_age) * 12
  end

  def bonus_per_month
    @config["deferral"]["bonus_per_month"]
  end

  def oas_config_file_path
    if ENV["APP_ENV"] == "test"
      File.expand_path("../config/oas_fixed.yml", __dir__)
    else
      File.expand_path("../config/oas.yml", __dir__)
    end
  end
end

# frozen_string_literal: true

module Strategy
  class RRIFWithdrawalCalculator
    def initialize
      config_file_path = withdrawal_config_file_path
      @withdrawal_rates = load_withdrawal_config(config_file_path)
      @min_age = @withdrawal_rates.keys.min
    end

    def withdrawal_amount(age, balance)
      return 0 if age < 71

      rate = @withdrawal_rates[age] || @withdrawal_rates[95] # Default to 95+ rate if age is missing
      (balance * rate)
    end

    def mandatory_withdrawal?(age)
      age >= @min_age
    end

    private

    def withdrawal_config_file_path
      if ENV["APP_ENV"] == "test"
        File.expand_path("../../config/rrif_fixed.yml", __dir__)
      else
        File.expand_path("../../config/rrif.yml", __dir__)
      end
    end

    def load_withdrawal_config(path)
      config = YAML.load_file(path)
      config.fetch("withdrawal_rates") { raise "Missing withdrawal_rates in #{path}" }
    rescue StandardError => e
      raise "Error loading RRIF withdrawal configuration from #{path}: #{e.message}"
    end
  end
end

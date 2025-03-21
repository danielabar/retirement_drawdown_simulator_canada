# frozen_string_literal: true

module Tax
  class IncomeTaxCalculator
    def initialize
      tax_file_path = tax_config_file_path
      @tax_config = load_tax_config(tax_file_path)
    end

    def calculate(gross_income, province_code)
      federal_tax = calculate_federal_tax(gross_income)
      provincial_tax = calculate_provincial_tax(gross_income, province_code)
      total_tax = federal_tax + provincial_tax

      {
        federal_tax: federal_tax,
        provincial_tax: provincial_tax,
        total_tax: total_tax,
        take_home: gross_income - total_tax
      }
    end

    private

    def tax_config_file_path
      if ENV["APP_ENV"] == "test"
        File.expand_path("../../config/tax_fixed.yml", __dir__)
      else
        File.expand_path("../../config/tax.yml", __dir__)
      end
    end

    def load_tax_config(path)
      YAML.load_file(path)
    rescue StandardError => e
      raise "Error loading tax configuration from #{path}: #{e.message}"
    end

    def calculate_federal_tax(gross_income)
      federal_brackets = @tax_config["federal"]["brackets"]
      federal_rates = @tax_config["federal"]["rates"]
      federal_exemption = @tax_config["federal"]["exemption"]

      tax_before_credit = apply_progressive_tax(gross_income, federal_brackets, federal_rates)
      tax_credit = federal_exemption * federal_rates.first # Apply lowest tax rate to exemption
      [tax_before_credit - tax_credit, 0].max # Tax can't be negative
    end

    def calculate_provincial_tax(gross_income, province_code)
      province_data = province_data_for(province_code)
      provincial_brackets = province_data["brackets"]
      provincial_rates = province_data["rates"]
      provincial_exemption = province_data["exemption"]

      tax_before_credit = apply_progressive_tax(gross_income, provincial_brackets, provincial_rates)
      tax_credit = provincial_exemption * provincial_rates.first # Apply lowest tax rate to exemption
      [tax_before_credit - tax_credit, 0].max # Tax can't be negative
    end

    def apply_progressive_tax(income, brackets, rates)
      tax = 0
      previous_bracket = 0

      brackets.each_with_index do |bracket, index|
        if income > bracket
          tax += (bracket - previous_bracket) * rates[index]
          previous_bracket = bracket
        else
          tax += (income - previous_bracket) * rates[index]
          return tax
        end
      end

      # Apply top rate to any income above the last bracket
      tax += (income - previous_bracket) * rates.last if income > previous_bracket
      tax
    end

    def province_data_for(province_code)
      @tax_config.fetch(province_code) do
        raise ArgumentError, "Invalid province code: #{province_code}"
      end
    end
  end
end

# frozen_string_literal: true

module Tax
  class IncomeTaxCalculator
    CONFIG_PATH = File.join(__dir__, "../../config/tax.yml")

    def initialize
      @tax_config = YAML.load_file(CONFIG_PATH)
    end

    def calculate(gross_income, province_code)
      federal_tax = calculate_tax(
        gross_income,
        @tax_config["federal"]["brackets"],
        @tax_config["federal"]["rates"],
        @tax_config["federal"]["exemption"]
      )

      province_data = @tax_config[province_code]
      raise ArgumentError, "Invalid province code: #{province_code}" unless province_data

      provincial_tax = calculate_tax(
        gross_income,
        province_data["brackets"],
        province_data["rates"],
        province_data["exemption"]
      )

      total_tax = federal_tax + provincial_tax
      take_home = gross_income - total_tax

      {
        provincial_tax: provincial_tax,
        federal_tax: federal_tax,
        total_tax: total_tax,
        take_home: take_home
      }
    end

    private

    def calculate_tax(income, brackets, rates, exemption)
      taxable_income = [income - exemption, 0].max
      tax = 0
      previous_bracket = 0

      (brackets + [Float::INFINITY]).zip(rates).each do |bracket, rate|
        if taxable_income > bracket
          tax += (bracket - previous_bracket) * rate
          previous_bracket = bracket
        else
          tax += (taxable_income - previous_bracket) * rate
          break
        end
      end

      tax
    end
  end
end

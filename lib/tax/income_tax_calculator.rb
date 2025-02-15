# frozen_string_literal: true

module Tax
  class IncomeTaxCalculator
    CONFIG_PATH = File.join(__dir__, "../../config/tax.yml")

    def initialize
      @tax_config = YAML.load_file(CONFIG_PATH)
    end

    def calculate(gross_income, province_code)
      federal_tax    = calculate_federal_tax(gross_income)
      provincial_tax = calculate_provincial_tax(gross_income, province_code)
      total_tax      = federal_tax + provincial_tax

      {
        federal_tax: federal_tax,
        provincial_tax: provincial_tax,
        total_tax: total_tax,
        take_home: gross_income - total_tax
      }
    end

    private

    def calculate_federal_tax(gross_income)
      fed_config = @tax_config["federal"]
      calculate_tax(gross_income, fed_config["brackets"],
                    fed_config["rates"],
                    fed_config["exemption"])
    end

    def calculate_provincial_tax(gross_income, province_code)
      province_data = province_data_for(province_code)
      calculate_tax(gross_income, province_data["brackets"],
                    province_data["rates"],
                    province_data["exemption"])
    end

    def province_data_for(province_code)
      @tax_config.fetch(province_code) do
        raise ArgumentError, "Invalid province code: #{province_code}"
      end
    end

    def calculate_tax(income, brackets, rates, exemption)
      taxable = taxable_income(income, exemption)
      compute_tax(taxable, brackets, rates)
    end

    def taxable_income(income, exemption)
      [income - exemption, 0].max
    end

    def compute_tax(taxable, brackets, rates)
      tax = 0
      previous_bracket = 0

      (brackets + [Float::INFINITY]).zip(rates).each do |bracket, rate|
        if taxable > bracket
          tax += (bracket - previous_bracket) * rate
          previous_bracket = bracket
        else
          tax += (taxable - previous_bracket) * rate
          break
        end
      end

      tax
    end
  end
end

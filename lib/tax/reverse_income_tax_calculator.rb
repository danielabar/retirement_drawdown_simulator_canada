# frozen_string_literal: true

module Tax
  class ReverseIncomeTaxCalculator
    CONFIG_PATH = File.join(__dir__, "../../config/tax.yml")

    def initialize
      @tax_config = YAML.load_file(CONFIG_PATH)
    end

    def calculate(desired_take_home, province_code)
      gross_income = find_gross_income_for_take_home(desired_take_home, province_code)
      build_tax_details(gross_income, province_code)
    end

    private

    def find_gross_income_for_take_home(desired_take_home, province_code)
      gross_income = desired_take_home.to_f
      loop do
        return gross_income if take_home_for(gross_income, province_code) >= desired_take_home

        gross_income += 0.01
      end
    end

    def take_home_for(gross_income, province_code)
      fed_tax  = calculate_federal_tax(gross_income)
      prov_tax = calculate_provincial_tax(gross_income, province_code)
      gross_income - (fed_tax + prov_tax)
    end

    def build_tax_details(gross_income, province_code)
      fed_tax  = calculate_federal_tax(gross_income)
      prov_tax = calculate_provincial_tax(gross_income, province_code)
      total_tax = fed_tax + prov_tax

      {
        gross_income: gross_income.round(2),
        federal_tax: fed_tax,
        provincial_tax: prov_tax,
        total_tax: total_tax,
        take_home: gross_income - total_tax
      }
    end

    def calculate_federal_tax(gross_income)
      fed_config = @tax_config["federal"]
      calculate_tax(gross_income,
                    fed_config["brackets"],
                    fed_config["rates"],
                    fed_config["exemption"])
    end

    def calculate_provincial_tax(gross_income, province_code)
      province_data = province_data_for(province_code)
      calculate_tax(gross_income,
                    province_data["brackets"],
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
        segment_tax, new_previous = compute_tax_for_segment(taxable, previous_bracket, bracket, rate)
        tax += segment_tax
        break if taxable <= bracket

        previous_bracket = new_previous
      end

      tax
    end

    def compute_tax_for_segment(taxable, previous_bracket, bracket, rate)
      if taxable > bracket
        [(bracket - previous_bracket) * rate, bracket]
      else
        [(taxable - previous_bracket) * rate, previous_bracket]
      end
    end
  end
end

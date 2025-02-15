# frozen_string_literal: true

module Tax
  class ReverseIncomeTaxCalculator
    CONFIG_PATH = File.join(__dir__, "../../config/tax.yml")

    def initialize
      @tax_config = YAML.load_file(CONFIG_PATH)
    end

    # Given a desired take-home income and a province code,
    # returns a hash with the necessary gross income and tax details.
    def calculate(desired_take_home, province_code)
      gross_income = desired_take_home.to_f

      loop do
        fed_tax    = calculate_federal_tax(gross_income)
        prov_tax   = calculate_provincial_tax(gross_income, province_code)
        total_tax  = fed_tax + prov_tax
        take_home  = gross_income - total_tax

        # Stop when our computed take-home is at least the desired amount.
        break if take_home >= desired_take_home

        gross_income += 0.01
      end

      {
        gross_income: gross_income.round(2),
        federal_tax: calculate_federal_tax(gross_income),
        provincial_tax: calculate_provincial_tax(gross_income, province_code),
        total_tax: gross_income - (gross_income - calculate_federal_tax(gross_income) - calculate_provincial_tax(
          gross_income, province_code
        )),
        take_home: gross_income - calculate_federal_tax(gross_income) - calculate_provincial_tax(gross_income,
                                                                                                 province_code)
      }
    end

    private

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

    # Computes the total tax for the given taxable income across all tax brackets.
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

    # Computes the tax for a single bracket segment.
    # Returns a two-element array: [tax_for_segment, updated_previous_bracket]
    def compute_tax_for_segment(taxable, previous_bracket, bracket, rate)
      if taxable > bracket
        [(bracket - previous_bracket) * rate, bracket]
      else
        [(taxable - previous_bracket) * rate, previous_bracket]
      end
    end
  end
end

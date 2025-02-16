# frozen_string_literal: true

require "yaml"

module Tax
  class ReverseIncomeTaxCalculator
    CONFIG_PATH = File.join(__dir__, "../../config/tax.yml")

    # TODO: Consider option to load hash for testing,
    # otherwise each year as tax rates change, test results will also change.
    # def initialize(cache: Util::FileCache.new)
    # def initialize(cache: Util::NullCache.new)
    def initialize(cache: Util::MemoryCache.instance)
      @tax_config = YAML.load_file(CONFIG_PATH)
      @cache = cache
    end

    def calculate(desired_take_home, province_code)
      # temp debug
      # puts "=== CALCULATE: #{desired_take_home} and #{province_code} ==="
      cache_key = "reverse_tax:#{desired_take_home}:#{province_code}"
      cached_result = @cache.fetch(cache_key)
      # temp debug
      # puts "=== CACHE HIT FOR #{cache_key} ===" if cached_result
      return cached_result if cached_result

      result = compute_tax_details(desired_take_home, province_code)
      @cache.store(cache_key, result)
      # temp debug
      # puts "=== CACHE MISS FOR #{cache_key} ==="
      result
    end

    private

    def compute_tax_details(desired_take_home, province_code)
      gross_income = find_gross_income_for_take_home(desired_take_home, province_code)
      build_tax_details(gross_income, province_code)
    end

    def find_gross_income_for_take_home(desired_take_home, province_code)
      lower_bound = desired_take_home
      upper_bound = desired_take_home * 1.5 # Initial guess
      tolerance = 0.01

      find_gross_income_in_range(lower_bound, upper_bound, desired_take_home, province_code, tolerance)
    end

    def find_gross_income_in_range(lower_bound, upper_bound, desired_take_home, province_code, tolerance)
      while (upper_bound - lower_bound) > tolerance
        mid_income = calculate_mid_income(lower_bound, upper_bound)
        calculated_take_home = take_home_for(mid_income, province_code)

        if calculated_take_home < desired_take_home
          lower_bound = mid_income
        else
          upper_bound = mid_income
        end
      end

      upper_bound.round(2) # Ensures the gross income is rounded properly
    end

    def calculate_mid_income(lower_bound, upper_bound)
      (lower_bound + upper_bound) / 2.0
    end

    def take_home_for(gross_income, province_code)
      total_tax = calculate_federal_tax(gross_income) + calculate_provincial_tax(gross_income, province_code)
      gross_income - total_tax
    end

    def build_tax_details(gross_income, province_code)
      federal_tax = calculate_federal_tax(gross_income)
      provincial_tax = calculate_provincial_tax(gross_income, province_code)
      total_tax = federal_tax + provincial_tax

      {
        gross_income: gross_income.round(2),
        federal_tax: federal_tax.round(2),
        provincial_tax: provincial_tax.round(2),
        total_tax: total_tax.round(2),
        take_home: (gross_income - total_tax).round(2)
      }
    end

    def calculate_federal_tax(gross_income)
      fed_config = @tax_config["federal"]
      calculate_tax(gross_income, fed_config["brackets"], fed_config["rates"], fed_config["exemption"])
    end

    def calculate_provincial_tax(gross_income, province_code)
      province_data = province_data_for(province_code)
      calculate_tax(gross_income, province_data["brackets"], province_data["rates"], province_data["exemption"])
    end

    def calculate_tax(income, brackets, rates, exemption)
      tax_before_credit = apply_progressive_tax(income, brackets, rates)
      tax_credit = exemption * rates.first # Apply lowest tax rate to exemption
      [tax_before_credit - tax_credit, 0].max # Tax cannot be negative
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

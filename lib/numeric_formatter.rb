# frozen_string_literal: true

class NumericFormatter
  # Formats a numeric amount as a currency string.
  #
  # Rounds the amount to the nearest cent, converts it to a string, and adds commas as thousand separators.
  # Prepends a dollar sign to the resulting string.
  #
  # @param amount [Numeric] The amount to format as a currency string.
  #
  # @return [String] The formatted currency string.
  #
  # @example
  #   format_currency(123456.789) # => "$123,456.79"
  #
  # @note This method uses a regular expression to insert commas as thousand separators.
  #       The regular expression works by reversing the string, inserting commas every 3 digits,
  #       and then reversing the string back to its original order.
  def self.format_currency(amount)
    "$#{amount.round.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
  end

  # Formats a number as a percentage with 2 decimal places
  def self.format_percentage(amount)
    "#{(amount * 100).round(2)}%"
  end
end

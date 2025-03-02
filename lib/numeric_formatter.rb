# frozen_string_literal: true

class NumericFormatter
  # Formats a number as currency
  # def self.format_currency(amount)
  #   "$#{format('%.2f', amount).reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
  # end
  def self.format_currency(amount)
    "$#{amount.round.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
  end

  # Formats a number as a percentage with 2 decimal places
  def self.format_percentage(amount)
    "#{(amount * 100).round(2)}%"
  end
end

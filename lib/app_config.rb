# frozen_string_literal: true

class AppConfig
  attr_reader :data

  def initialize(config)
    @data = config.is_a?(String) ? YAML.load_file(config) : config
  end

  def [](key)
    data[key]
  end

  def accounts
    data["accounts"]
  end

  def cpp
    data["cpp"]
  end

  def taxes
    data["taxes"]
  end

  def annual_growth_rate
    data["annual_growth_rate"]
  end

  def summary
    total_balance = accounts.values.sum
    retirement_duration = data["max_age"] - data["retirement_age"]

    {
      starting_balances: accounts,
      starting_total_balance: total_balance,
      intended_retirement_duration: retirement_duration
    }
  end
end

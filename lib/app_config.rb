# frozen_string_literal: true

require "yaml"

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
end

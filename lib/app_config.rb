# frozen_string_literal: true

require "yaml"

class AppConfig
  attr_reader :data

  def initialize(config_path)
    @data = YAML.load_file(config_path)
  end

  def [](key)
    data[key]
  end

  def accounts
    data["accounts"]
  end

  def taxes
    data["taxes"]
  end

  def annual_growth_rate
    data["annual_growth_rate"]
  end
end

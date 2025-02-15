# frozen_string_literal: true

require_relative "config/environment"

# Run::AppRunner.new("inputs.yml", ARGV[0]).run
Run::AppRunner.new("spec/fixtures/example_input_low_growth.yml", ARGV[0]).run

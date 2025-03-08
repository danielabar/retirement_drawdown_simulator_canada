# frozen_string_literal: true

require_relative "config/environment"

Run::AppRunner.new("inputs.yml", ARGV[0]).run
# Run::AppRunner.new("inputs_demo.yml", ARGV[0]).run

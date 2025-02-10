# frozen_string_literal: true

require_relative "config/environment"

AppRunner.new("inputs_example.yml", ARGV[0]).run

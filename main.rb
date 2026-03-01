# frozen_string_literal: true

require_relative "config/environment"

# Usage:
#   ruby main.rb                                          # detailed mode, reads inputs.yml
#   ruby main.rb detailed                                 # same, explicit
#   ruby main.rb success_rate                             # success_rate mode, reads inputs.yml
#   ruby main.rb demo/four_percent_rule.yml               # reads custom file, mode from YAML or defaults to detailed
#   ruby main.rb success_rate demo/four_percent_rule.yml  # success_rate mode, custom file
#   ruby main.rb demo/four_percent_rule.yml success_rate  # same — argument order doesn't matter
#
# If no inputs file is given, reads inputs.yml from the project root.
# If no mode is given on the command line, falls back to the mode key in the inputs file, then "detailed".

mode_arg   = ARGV.find { |a| %w[detailed success_rate].include?(a) }
inputs_arg = ARGV.find { |a| a.end_with?(".yml") }

puts "Main: Running with mode: #{mode_arg || '(from inputs file)'}, inputs file: #{inputs_arg || 'inputs.yml (default)'}"

Run::AppRunner.new(inputs_arg || "inputs.yml", mode_arg).run

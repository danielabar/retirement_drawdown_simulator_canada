# frozen_string_literal: true

require_relative "config/environment"
puts "Loaded application"

IRB.conf[:PROMPT][:APP] = {
  PROMPT_I: "drawdown_simulator> ",  # Standard input prompt
  PROMPT_N: "drawdown_simulator* ",  # Multiline input
  PROMPT_S: "drawdown_simulator%l ", # String continuation
  PROMPT_C: "drawdown_simulator? ",  # Indentation level
  RETURN: "=> %s\n" # Format of return value
}

IRB.conf[:PROMPT_MODE] = :APP # Set custom prompt

# Reloads the current IRB session.
#
# This is useful when you want to re-run your .irbrc file to pick up
# changes, or when you want to try out a new version of the app.
def reload!
  exec "irb"
end

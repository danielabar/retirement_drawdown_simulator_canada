# frozen_string_literal: true

require "debug"
require "yaml"

Dir.glob(File.expand_path("../lib/**/*.rb", __dir__)).each { |file| require file }

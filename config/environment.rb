# frozen_string_literal: true

require "debug"
require "descriptive_statistics"
require "tty-progressbar"
require "tty-table"
require "unicode_plot"
require "yaml"

Dir.glob(File.expand_path("../lib/**/*.rb", __dir__)) { |file| require file }

# frozen_string_literal: true

module Util
  class FileCache
    CACHE_DIR = File.expand_path("tmp/cache", "#{__dir__}/../../")

    def initialize
      FileUtils.mkdir_p(CACHE_DIR)
    end

    def fetch(key)
      cache_file = cache_path(key)
      return nil unless File.exist?(cache_file)

      JSON.parse(File.read(cache_file), symbolize_names: true)
    end

    def store(key, value)
      File.write(cache_path(key), value.to_json)
    end

    private

    def cache_path(key)
      filename = "#{Digest::SHA256.hexdigest(key)}.json"
      File.join(CACHE_DIR, filename)
    end
  end
end

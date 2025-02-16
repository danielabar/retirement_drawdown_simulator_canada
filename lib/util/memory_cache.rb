# frozen_string_literal: true

module Util
  class MemoryCache
    include Singleton

    def initialize
      @cache = {}
    end

    def fetch(key)
      @cache[key]
    end

    def store(key, value)
      @cache[key] = value
    end

    def clear
      @cache.clear
    end
  end
end

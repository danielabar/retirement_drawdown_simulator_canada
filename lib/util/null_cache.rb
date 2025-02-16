# frozen_string_literal: true

module Util
  class NullCache
    def fetch(_key)
      nil
    end

    def store(_key, _value)
      # No-op
    end
  end
end

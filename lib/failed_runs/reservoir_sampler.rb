# frozen_string_literal: true

module FailedRuns
  # Streaming K-of-N reservoir sampler (Algorithm R).
  #
  # Why reservoir? Failures stream in as the simulator runs N independent trials,
  # and we don't know upfront how many failures will occur. Naively keeping
  # "the first K" biases the saved set toward whatever the early iterations
  # happened to produce. Reservoir sampling guarantees that every item in the
  # stream has equal probability (K / total_seen) of ending up in the saved set,
  # regardless of when it streamed past — without needing to know the total
  # count upfront and without buffering everything.
  #
  # Algorithm:
  #   - For the first K items: keep them all.
  #   - For item i (i > K): draw a random integer j in [0, i). If j < K, the
  #     new item replaces slot j. Otherwise discard.
  class ReservoirSampler
    def initialize(capacity, rng: Random.new)
      @capacity = capacity
      @rng = rng
      @items = []
      @seen_count = 0
    end

    def offer(item)
      @seen_count += 1
      if @items.size < @capacity
        @items << item
      else
        j = @rng.rand(@seen_count)
        @items[j] = item if j < @capacity
      end
    end

    def to_a
      @items.dup
    end

    attr_reader :seen_count, :capacity
  end
end

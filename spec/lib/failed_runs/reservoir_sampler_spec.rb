# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe FailedRuns::ReservoirSampler do
  describe "#offer / #to_a" do
    it "keeps all items when fewer than capacity offered" do
      sampler = described_class.new(3)
      %i[a b c].each { |i| sampler.offer(i) }
      expect(sampler.to_a).to eq(%i[a b c])
    end

    it "stays at capacity when more than capacity offered" do
      sampler = described_class.new(3)
      1000.times { |i| sampler.offer(i) }
      expect(sampler.to_a.size).to eq(3)
      expect(sampler.seen_count).to eq(1000)
    end
  end

  describe "uniform inclusion probability" do
    it "each offered item has approximately K/N probability of inclusion" do
      capacity = 3
      stream_size = 100
      target_item = 50
      trials = 10_000
      rng = Random.new(42)

      hits = 0
      trials.times do
        sampler = described_class.new(capacity, rng: rng)
        stream_size.times { |i| sampler.offer(i) }
        hits += 1 if sampler.to_a.include?(target_item)
      end

      empirical = hits.to_f / trials
      expected = capacity.to_f / stream_size
      expect(empirical).to be_within(0.015).of(expected)
    end
  end
end

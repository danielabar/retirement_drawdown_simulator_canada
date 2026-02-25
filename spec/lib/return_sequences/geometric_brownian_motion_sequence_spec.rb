# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe ReturnSequences::GeometricBrownianMotionSequence do
  let(:avg) { 0.05 }  # 5% average return
  let(:min) { -0.2 }  # -20% minimum return
  let(:max) { 0.3 }   # 30% maximum return
  let(:start_age) { 65 }
  let(:max_age) { 75 }
  let(:gbm) { described_class.new(start_age, max_age, avg, min, max) }

  before do
    srand(1234)
  end

  describe "#generate_returns" do
    it "returns a hash with the correct number of entries" do
      result = gbm.send(:generate_returns)
      expect(result.size).to eq(max_age - start_age + 1) # One entry per age
    end

    it "has ages as the keys" do
      result = gbm.send(:generate_returns)
      expect(result.keys).to eq((start_age..max_age).to_a)
    end

    it "generates valid returns for each age" do
      result = gbm.send(:generate_returns)
      result.each_value do |return_value|
        # Ensure the return is a float, rounded to 4 decimal places
        expect(return_value).to be_a(Float)
        expect(return_value).to eq(return_value.round(4))
      end
    end

    it "calculates returns within reasonable range" do
      result = gbm.send(:generate_returns)
      result.each_value do |return_value|
        # Returns should generally stay within [-1, 1] (i.e., -100% to 100%)
        expect(return_value).to be_between(-1.0, 1.0)
      end
    end
  end

  describe "#compute_sigma" do
    it "computes sigma based on the deviation between min, avg, and max" do
      expected_sigma = [max - avg, avg - min].max / 3.0
      expect(gbm.send(:compute_sigma)).to eq(expected_sigma)
    end
  end

  describe "#rand_normal" do
    it "generates random numbers that follow a standard normal distribution" do
      mean = 0.0
      stddev = 1.0
      sample = Array.new(1000) { gbm.send(:rand_normal, mean, stddev) }

      # Check if the sample mean is close to 0 and standard deviation is close to 1
      sample_mean = sample.sum / sample.size
      sample_stddev = Math.sqrt(sample.sum { |x| (x - sample_mean)**2 } / sample.size)

      expect(sample_mean).to be_within(0.1).of(mean)
      expect(sample_stddev).to be_within(0.1).of(stddev)
    end
  end

  describe "#rand_student_t" do
    it "has a mean close to 0" do
      sample = Array.new(2000) { gbm.send(:rand_student_t, degrees_of_freedom: 5) }
      sample_mean = sample.sum / sample.size
      expect(sample_mean).to be_within(0.15).of(0.0)
    end

    it "produces a wider spread than rand_normal over the same sample" do
      normal_sample = Array.new(2000) { gbm.send(:rand_normal) }
      t_sample      = Array.new(2000) { gbm.send(:rand_student_t, degrees_of_freedom: 5) }

      normal_stddev = Math.sqrt(normal_sample.sum { |x| (x - 0)**2 } / normal_sample.size)
      t_stddev      = Math.sqrt(t_sample.sum { |x| (x - 0)**2 } / t_sample.size)

      # Student-t with df=5 has variance df/(df-2) = 5/3 ≈ 1.67, so stddev ≈ 1.29
      # Normal has stddev = 1.0, so t should be consistently wider
      expect(t_stddev).to be > normal_stddev
    end
  end
end

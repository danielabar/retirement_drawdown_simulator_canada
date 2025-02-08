# frozen_string_literal: true

require "rspec"

# TODO: remove - no longer used
RSpec.describe ReturnSequence do
  subject(:return_sequence) { described_class.new(start_age, max_age, avg, min, max) }

  let(:start_age) { 60 }
  let(:max_age) { 64 }
  let(:avg) { 0.03 }
  let(:min) { -0.3 }
  let(:max) { 0.3 }

  describe "#get_return_for_age" do
    before do
      srand(1234) # Set a fixed seed for randomness in tests
    end

    it "returns a value between the min and max for each age" do
      (start_age..max_age).each do |age|
        return_value = return_sequence.get_return_for_age(age)
        expect(return_value).to be_between(min, max).inclusive
      end
    end

    it "returns the expected average return over all ages" do
      returns = (start_age..max_age).map { |age| return_sequence.get_return_for_age(age) }
      actual_avg = returns.sum / returns.size
      expect(actual_avg).to be_within(0.001).of(avg)
    end

    it "raises an error when the average return cannot be generated after some maximum number of attempts" do
      invalid_avg = 0.6
      invalid_min = 0.7
      invalid_max = 0.9

      invalid_return_sequence = described_class.new(start_age, max_age, invalid_avg, invalid_min, invalid_max)

      expect do
        invalid_return_sequence.get_return_for_age(start_age)
      end.to raise_error(/^Unable to generate a return sequence/)
    end

    context "when returns are constant" do
      let(:min) { 0.03 }
      let(:max) { 0.03 }

      it "returns the constant average return for each age" do
        (start_age..max_age).each do |age|
          expect(return_sequence.get_return_for_age(age)).to eq(avg)
        end
      end
    end
  end
end

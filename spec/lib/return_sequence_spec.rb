# frozen_string_literal: true

require "rspec"

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
      # Allow for a small margin of error due to floating point precision and randomness
      expect(actual_avg).to be_within(0.001).of(avg)
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

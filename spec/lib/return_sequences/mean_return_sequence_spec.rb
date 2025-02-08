# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe ReturnSequences::MeanReturnSequence do
  subject(:mean_return_sequence) { described_class.new(start_age, max_age, avg, min, max) }

  let(:start_age) { 60 }
  let(:max_age) { 64 }
  let(:avg) { 0.05 }
  let(:min) { -0.2 }
  let(:max) { 0.2 }

  describe "#get_return_for_age" do
    before do
      srand(1234)
    end

    context "when returns are valid" do
      it "returns a valid return for each age" do
        (start_age..max_age).each do |age|
          expect(mean_return_sequence.get_return_for_age(age)).to be_between(min, max)
        end
      end

      it "returns the adjusted value to meet the target average" do
        returns = (start_age..max_age).map { |age| mean_return_sequence.get_return_for_age(age) }
        actual_avg = returns.sum.to_f / returns.size
        expect(actual_avg).to be_within(0.001).of(avg)
      end
    end
  end
end

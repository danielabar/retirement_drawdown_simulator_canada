# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe ReturnSequences::BaseSequence do
  describe "#returns_by_age" do
    let(:start_age) { 60 }
    let(:max_age) { 64 }
    let(:avg) { 0.05 }
    let(:min) { -0.2 }
    let(:max) { 0.2 }

    context "with a deterministic ConstantReturnSequence" do
      subject(:sequence) { ReturnSequences::ConstantReturnSequence.new(start_age, max_age, avg, min, max) }

      it "returns a hash with one entry per age in [start_age..max_age]" do
        expect(sequence.returns_by_age.keys).to eq((start_age..max_age).to_a)
      end

      it "values match get_return_for_age for each age" do
        (start_age..max_age).each do |age|
          expect(sequence.returns_by_age[age]).to eq(sequence.get_return_for_age(age))
        end
      end

      it "triggers generation lazily on a fresh instance" do
        fresh = ReturnSequences::ConstantReturnSequence.new(start_age, max_age, avg, min, max)
        expect(fresh.returns_by_age).not_to be_empty
      end

      it "returns a copy so callers cannot mutate the internal map" do
        copy = sequence.returns_by_age
        copy[start_age] = 999.0
        expect(sequence.returns_by_age[start_age]).to eq(avg)
      end
    end

    context "with a MeanReturnSequence (seeded for determinism)" do
      subject(:sequence) { ReturnSequences::MeanReturnSequence.new(start_age, max_age, avg, min, max) }

      before { srand(1234) }

      it "values match get_return_for_age for each age" do
        hash = sequence.returns_by_age
        (start_age..max_age).each do |age|
          expect(hash[age]).to eq(sequence.get_return_for_age(age))
        end
      end
    end
  end
end

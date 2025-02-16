# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe Tax::ReverseIncomeTaxCalculator do
  subject(:reverse_calculator) { described_class.new }

  describe "#calculate" do
    context "when desired take-home is $40,000" do
      let(:desired_take_home) { 40_000 }

      it "calculates the correct gross income needed for Ontario (ONT)" do
        result = reverse_calculator.calculate(desired_take_home, "ONT")

        expect(result[:gross_income]).to be_within(0.1).of(46_200.04)
        expect(result[:federal_tax]).to be_within(0.1).of(4510.66)
        expect(result[:provincial_tax]).to be_within(0.1).of(1689.38)
        expect(result[:total_tax]).to be_within(0.1).of(6200.03)
        expect(result[:take_home]).to be_within(0.1).of(40_000.00)
      end

      it "calculates the correct gross income needed for Alberta (AB)" do
        result = reverse_calculator.calculate(desired_take_home, "AB")

        expect(result[:gross_income]).to be_within(0.1).of(47_131.14)
        expect(result[:federal_tax]).to be_within(0.1).of(4650.321)
        expect(result[:provincial_tax]).to be_within(0.1).of(2480.814)
        expect(result[:total_tax]).to be_within(0.1).of(7131.135)
        expect(result[:take_home]).to be_within(0.1).of(40_000.005)
      end
    end

    context "when desired take-home is $160,000" do
      let(:desired_take_home) { 160_000 }

      it "calculates the correct gross income needed for Ontario (ONT)" do
        result = reverse_calculator.calculate(desired_take_home, "ONT")

        expect(result[:gross_income]).to be_within(0.1).of(231_914.23)
        expect(result[:federal_tax]).to be_within(0.1).of(50_032.44)
        expect(result[:provincial_tax]).to be_within(0.1).of(21_881.79)
        expect(result[:total_tax]).to be_within(0.1).of(71_914.23)
        expect(result[:take_home]).to be_within(0.1).of(160_000.00)
      end

      it "calculates the correct gross income needed for Alberta (AB)" do
        result = reverse_calculator.calculate(desired_take_home, "AB")

        expect(result[:gross_income]).to be_within(0.1).of(233_975.05)
        expect(result[:federal_tax]).to be_within(0.1).of(50_630.08)
        expect(result[:provincial_tax]).to be_within(0.1).of(23_344.97)
        expect(result[:total_tax]).to be_within(0.1).of(73_975.05)
        expect(result[:take_home]).to be_within(0.1).of(160_000.00)
      end
    end

    context "when an unknown province code is provided" do
      let(:desired_take_home) { 40_000 }

      it "raises an error" do
        expect { reverse_calculator.calculate(desired_take_home, "ZZ") }
          .to raise_error(ArgumentError)
      end
    end
  end
end

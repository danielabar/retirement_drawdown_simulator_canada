# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe Tax::IncomeTaxCalculator do
  subject(:calculator) { described_class.new }

  describe "#calculate" do
    context "when income is within low tax brackets" do
      let(:gross_income) { 40_000 }

      it "calculates correct tax values for Ontario (ONT) with 40,000 income" do
        result = calculator.calculate(gross_income, "ONT")

        expect(result[:total_tax]).to be_within(1).of(4_956)
        expect(result[:take_home]).to be_within(1).of(35_044)
        expect(result[:provincial_tax]).to be_within(1).of(1_376.28)
        expect(result[:federal_tax]).to be_within(1).of(3_580.65)
      end

      it "calculates correct tax values for Alberta (AB) with 40,000 income" do
        result = calculator.calculate(gross_income, "AB")

        expect(result[:total_tax]).to be_within(1).of(5_348)
        expect(result[:take_home]).to be_within(1).of(34_652)
        expect(result[:provincial_tax]).to be_within(1).of(1_768.00)
        expect(result[:federal_tax]).to be_within(1).of(3_580.00)
      end
    end

    context "when income is within higher tax brackets" do
      let(:gross_income) { 160_000 }

      it "calculates correct tax values for Ontario (ONT) with 160,000 income" do
        result = calculator.calculate(gross_income, "ONT")
        expect(result[:total_tax]).to be_within(1).of(42_732)
        expect(result[:take_home]).to be_within(1).of(117_268)
        expect(result[:provincial_tax]).to be_within(1).of(13_018)
        expect(result[:federal_tax]).to be_within(1).of(29_714)
      end

      it "calculates correct tax values for Alberta (AB) with 160,000 income" do
        result = calculator.calculate(gross_income, "AB")

        expect(result[:total_tax]).to be_within(1).of(43_657)
        expect(result[:take_home]).to be_within(1).of(116_343)
        expect(result[:provincial_tax]).to be_within(1).of(13_943)
        expect(result[:federal_tax]).to be_within(1).of(29_714)
      end
    end

    context "when income is over and above highest federal and provincial tax brackets" do
      let(:gross_income) { 260_000 }

      it "calculates correct tax values for Ontario (ONT) with 260,000 income" do
        result = calculator.calculate(gross_income, "ONT")

        expect(result[:total_tax]).to be_within(1).of(84_018.628)
        expect(result[:take_home]).to be_within(1).of(175_981.372)
        expect(result[:provincial_tax]).to be_within(1).of(25_577.873)
        expect(result[:federal_tax]).to be_within(1).of(58_440.755)
      end
    end

    context "when unknown province code is given" do
      let(:gross_income) { 40_000 }

      it "raises an error" do
        expect { calculator.calculate(gross_income, "ZZ") }.to raise_error(ArgumentError)
      end
    end
  end
end

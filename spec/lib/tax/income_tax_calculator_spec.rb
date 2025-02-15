# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe Tax::IncomeTaxCalculator do
  subject(:calculator) { described_class.new }

  describe "#calculate" do
    let(:gross_income) { 40_000 }

    context "when in ONT (Ontario)" do
      let(:province_code) { "ONT" }

      it "calculates correct tax values for ON with 40,000 income" do
        result = calculator.calculate(gross_income, province_code)

        expect(result[:total_tax]).to be_within(1).of(4_956)
        expect(result[:take_home]).to be_within(1).of(35_044)
        expect(result[:provincial_tax]).to be_within(1).of(1_376.28)
        expect(result[:federal_tax]).to be_within(1).of(3_580.65)
      end
    end

    context "when in AB (Alberta)" do
      let(:province_code) { "AB" }

      it "calculates correct tax values for AB with 40,000 income" do
        result = calculator.calculate(gross_income, province_code)

        expect(result[:total_tax]).to be_within(1).of(5_348)
        expect(result[:take_home]).to be_within(1).of(34_652)
        expect(result[:provincial_tax]).to be_within(1).of(1_768.00)
        expect(result[:federal_tax]).to be_within(1).of(3_580.00)
      end
    end
  end
end

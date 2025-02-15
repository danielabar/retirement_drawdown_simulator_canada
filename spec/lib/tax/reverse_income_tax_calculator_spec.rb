# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe Tax::ReverseIncomeTaxCalculator do
  subject(:reverse_calculator) { described_class.new }

  describe "#calculate" do
    let(:desired_take_home) { 40_000 }

    context "when in ONT (Ontario)" do
      let(:province_code) { "ONT" }

      it "calculates the correct gross income needed for a $40,000 take-home" do
        result = reverse_calculator.calculate(desired_take_home, province_code)

        expect(result[:gross_income]).to be_within(0.1).of(46_200.04)
        expect(result[:federal_tax]).to be_within(0.1).of(4510.66)
        expect(result[:provincial_tax]).to be_within(0.1).of(1689.38)
        expect(result[:total_tax]).to be_within(0.1).of(6200.03)
        expect(result[:take_home]).to be_within(0.1).of(40_000.00)
      end
    end

    context "when in AB (Alberta)" do
      let(:province_code) { "AB" }

      it "calculates the correct gross income needed for a $40,000 take-home" do
        result = reverse_calculator.calculate(desired_take_home, province_code)

        expect(result[:gross_income]).to be_within(0.1).of(47_131.14)
        expect(result[:federal_tax]).to be_within(0.1).of(4650.321)
        expect(result[:provincial_tax]).to be_within(0.1).of(2480.814)
        expect(result[:total_tax]).to be_within(0.1).of(7131.135)
        expect(result[:take_home]).to be_within(0.1).of(40_000.005)
      end
    end

    context "when an unknown province code is provided" do
      let(:province_code) { "ZZ" }

      it "raises an error" do
        expect { reverse_calculator.calculate(desired_take_home, province_code) }
          .to raise_error(ArgumentError)
      end
    end
  end
end

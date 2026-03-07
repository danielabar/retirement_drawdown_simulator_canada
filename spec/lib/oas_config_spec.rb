# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe OasConfig do
  subject(:oas_config) { described_class.new }

  describe "#base_monthly_amount" do
    it "returns the ages_65_to_74 rate for age 65" do
      expect(oas_config.base_monthly_amount(65)).to eq(742.31)
    end

    it "returns the ages_65_to_74 rate for age 74" do
      expect(oas_config.base_monthly_amount(74)).to eq(742.31)
    end

    it "returns the ages_75_plus rate for age 75" do
      expect(oas_config.base_monthly_amount(75)).to eq(816.54)
    end

    it "returns the ages_75_plus rate for age 80" do
      expect(oas_config.base_monthly_amount(80)).to eq(816.54)
    end
  end

  describe "#deferral_multiplier" do
    it "returns 1.0 for start_age 65 (no deferral)" do
      expect(oas_config.deferral_multiplier(65)).to eq(1.0)
    end

    it "returns 1.36 for start_age 70 (maximum deferral)" do
      expect(oas_config.deferral_multiplier(70)).to be_within(0.0001).of(1.36)
    end

    it "clamps start_age below 65 to 1.0 (no negative bonus)" do
      expect(oas_config.deferral_multiplier(63)).to eq(1.0)
    end

    it "clamps start_age above 70 to 1.36 (no bonus beyond maximum)" do
      expect(oas_config.deferral_multiplier(72)).to be_within(0.0001).of(1.36)
    end
  end

  describe "#minimum_residency_years" do
    it "returns 10" do
      expect(oas_config.minimum_residency_years).to eq(10)
    end
  end

  describe "#full_pension_residency_years" do
    it "returns 40" do
      expect(oas_config.full_pension_residency_years).to eq(40)
    end
  end
end

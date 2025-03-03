# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe AppConfig do
  subject(:app_config) { described_class.new(config_hash) }

  let(:config_hash) do
    {
      "mode" => "detailed",
      "retirement_age" => 65,
      "max_age" => 95,
      "province_code" => "ONT",
      "annual_tfsa_contribution" => 10,
      "desired_spending" => 30_000,
      "annual_growth_rate" => {
        "average" => 0.05,
        "min" => -0.3,
        "max" => 0.3,
        "downturn_threshold" => -0.2
      },
      "return_sequence_type" => "constant",
      "accounts" => {
        "rrsp" => 600_000,
        "taxable" => 200_000,
        "tfsa" => 200_000,
        "cash_cushion" => 40_000
      },
      "cpp" => {
        "start_age" => 65,
        "monthly_amount" => 0
      },
      "taxes" => {
        "rrsp_withholding_rate" => 0.3
      }
    }
  end

  describe "#[]" do
    it "returns the value for a given key" do
      expect(app_config["mode"]).to eq("detailed")
    end

    it "returns nil for an unknown key" do
      expect(app_config["unknown_key"]).to be_nil
    end
  end

  describe "#accounts" do
    it "returns the accounts values" do
      expect(app_config.accounts).to eq(
        "rrsp" => 600_000,
        "taxable" => 200_000,
        "tfsa" => 200_000,
        "cash_cushion" => 40_000
      )
    end
  end

  describe "#cpp" do
    it "returns the CPP values" do
      expect(app_config.cpp).to eq(
        "start_age" => 65,
        "monthly_amount" => 0
      )
    end
  end

  describe "#taxes" do
    it "returns the tax values" do
      expect(app_config.taxes).to eq(
        "rrsp_withholding_rate" => 0.3
      )
    end
  end

  describe "#annual_growth_rate" do
    it "returns the annual growth rate values" do
      expect(app_config.annual_growth_rate).to eq(
        "average" => 0.05,
        "min" => -0.3,
        "max" => 0.3,
        "downturn_threshold" => -0.2
      )
    end
  end

  describe "#summary" do
    it "returns a hash with values for starting balances, total balance, and retirement duration" do
      expected_summary = {
        starting_balances: {
          "rrsp" => 600_000,
          "taxable" => 200_000,
          "tfsa" => 200_000,
          "cash_cushion" => 40_000
        },
        starting_total_balance: 1_040_000,
        intended_retirement_duration: 30
      }

      expect(app_config.summary).to eq(expected_summary)
    end
  end
end

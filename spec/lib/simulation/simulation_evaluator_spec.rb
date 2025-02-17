# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe Simulation::SimulationEvaluator do
  let(:base_fixture_path) { File.expand_path("../../fixtures", __dir__) }
  let(:app_config) { AppConfig.new(File.join(base_fixture_path, "evaluator_input.yml")) }
  let(:evaluator) { described_class.new(simulation_results, app_config) }

  describe "evaluating RRSP Drawdown" do
    context "when simulation succeeds" do
      let(:simulation_results) do
        [{ age: 95, total_balance: 30_000, note: "rrsp" }]
      end

      it "is successful because max age reached and total bal is >= 1x RRSP withdrawal amount" do
        expect(evaluator.evaluate).to eq(
          success: true,
          explanation: "Simulation successful with total balance of $30,000.00.",
          withdrawal_rate: 0.02
        )
      end
    end

    context "when simulation fails because max age is not reached" do
      let(:simulation_results) do
        [{ age: 80, total_balance: 20_000, note: "rrsp" }]
      end

      it "fails because max age was not reached" do
        expect(evaluator.evaluate).to eq(
          success: false,
          explanation: "Simulation failed. Max age 95 not reached. Final age is 80.",
          withdrawal_rate: 0.02
        )
      end
    end

    context "when simulation fails due to insufficient total balance at max age" do
      let(:simulation_results) do
        [{ age: 95, total_balance: 15_000, note: "rrsp" }]
      end

      it "fails because total balance is less than the 1x RRSP withdrawal amount" do
        # when we're in rrsp phase, the success threshold is rrsp withdrawal amount which is
        # calculated by reverse income tax calculator based on desired_income and province_code
        expect(evaluator.evaluate).to eq(
          success: false,
          explanation: "Simulation failed. Max age reached, but total balance of $15,000.00 " \
                       "is below success threshold of $27,438.31.",
          withdrawal_rate: 0.02
        )
      end
    end
  end

  describe "evaluating Taxable Drawdown" do
    context "when simulation succeeds" do
      let(:simulation_results) do
        [{ age: 95, total_balance: 80_000, note: "taxable" }]
      end

      it "is successful because max age reached and total bal >= 1x desired spending plus TFSA contribution" do
        expect(evaluator.evaluate).to eq(
          success: true,
          explanation: "Simulation successful with total balance of $80,000.00.",
          withdrawal_rate: 0.02
        )
      end
    end

    context "when simulation fails because max age is not reached" do
      let(:simulation_results) do
        [{ age: 85, total_balance: 40_000, note: "taxable" }]
      end

      it "fails because max age was not reached" do
        expect(evaluator.evaluate).to eq(
          success: false,
          explanation: "Simulation failed. Max age 95 not reached. Final age is 85.",
          withdrawal_rate: 0.02
        )
      end
    end

    context "when simulation fails due to insufficient total balance at max age" do
      let(:simulation_results) do
        [{ age: 95, total_balance: 5_000, note: "taxable" }]
      end

      it "fails because total balance is less than the 1x desired spending plus TFSA contribution" do
        expect(evaluator.evaluate).to eq(
          success: false,
          explanation: "Simulation failed. Max age reached, but total balance of $5,000.00 " \
                       "is below success threshold of $25,000.00.",
          withdrawal_rate: 0.02
        )
      end
    end
  end

  describe "evaluating TFSA Drawdown" do
    context "when simulation succeeds" do
      let(:simulation_results) do
        [{ age: 95, total_balance: 60_000, note: "tfsa" }]
      end

      it "is successful because max age reached and total bal >= 1x desired spending" do
        expect(evaluator.evaluate).to eq(
          success: true,
          explanation: "Simulation successful with total balance of $60,000.00.",
          withdrawal_rate: 0.02
        )
      end
    end

    context "when simulation fails because max age is not reached" do
      let(:simulation_results) do
        [{ age: 80, total_balance: 30_000, note: "tfsa" }]
      end

      it "fails because max age was not reached" do
        expect(evaluator.evaluate).to eq(
          success: false,
          explanation: "Simulation failed. Max age 95 not reached. Final age is 80.",
          withdrawal_rate: 0.02
        )
      end
    end

    context "when simulation fails due to insufficient total balance at max age" do
      let(:simulation_results) do
        [{ age: 95, total_balance: 8_000, note: "tfsa" }]
      end

      it "fails because total balance is less than 1x desired spending" do
        expect(evaluator.evaluate).to eq(
          success: false,
          explanation: "Simulation failed. Max age reached, but total balance of $8,000.00 " \
                       "is below success threshold of $20,000.00.",
          withdrawal_rate: 0.02
        )
      end
    end
  end

  describe "evaluating with different success factors" do
    context "when success factor is 1.5 and balance is 1.5x withdrawal amount" do
      let(:app_config) { AppConfig.new(File.join(base_fixture_path, "evaluator_input_success_factor_1_5.yml")) }
      let(:simulation_results) do
        [{ age: 95, total_balance: 45_000, note: "rrsp" }]
      end

      it "requires a total balance of 1.5x the withdrawal amount to succeed" do
        expect(evaluator.evaluate).to eq(
          success: true,
          explanation: "Simulation successful with total balance of $45,000.00.",
          withdrawal_rate: 0.02
        )
      end
    end

    context "when success factor is 1.5 and balance is less than 1.5x withdrawal amount" do
      let(:app_config) { AppConfig.new(File.join(base_fixture_path, "evaluator_input_success_factor_1_5.yml")) }
      let(:simulation_results) do
        [{ age: 95, total_balance: 40_000, note: "rrsp" }]
      end

      it "fails because total balance is less than 1.5x withdrawal amount" do
        # when we're in rrsp phase, the success threshold is rrsp withdrawal amount which is
        # calculated by reverse income tax calculator based on desired_income and province_code
        expect(evaluator.evaluate).to eq(
          success: false,
          explanation: "Simulation failed. Max age reached, but total balance of $40,000.00 " \
                       "is below success threshold of $41,157.46.",
          withdrawal_rate: 0.02
        )
      end
    end

    context "when success factor is 2.0 and balance is 2x withdrawal amount" do
      let(:app_config) { AppConfig.new(File.join(base_fixture_path, "evaluator_input_success_factor_1_5.yml")) }
      let(:simulation_results) do
        [{ age: 95, total_balance: 60_000, note: "rrsp" }]
      end

      it "requires a total balance of 2x the withdrawal amount to succeed" do
        expect(evaluator.evaluate).to eq(
          success: true,
          explanation: "Simulation successful with total balance of $60,000.00.",
          withdrawal_rate: 0.02
        )
      end
    end
  end
end

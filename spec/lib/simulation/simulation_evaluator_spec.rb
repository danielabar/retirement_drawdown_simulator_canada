# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe Simulation::SimulationEvaluator do
  let(:base_fixture_path) { File.expand_path("../../fixtures", __dir__) }
  let(:app_config) { AppConfig.new(File.join(base_fixture_path, "evaluator_input.yml")) }
  let(:evaluator) { described_class.new(simulation_results, app_config) }

  describe "evaluating simulation success" do
    context "when simulation succeeds" do
      let(:simulation_results) do
        [{ age: 95, total_balance: 30_000 }]
      end

      it "is successful because max age reached and total balance is >= success threshold" do
        expect(evaluator.evaluate).to eq(
          success: true,
          explanation: "Simulation successful with total balance of $30,000.00.",
          withdrawal_rate: 0.02
        )
      end
    end

    context "when simulation fails due to max age not being reached" do
      let(:simulation_results) do
        [{ age: 80, total_balance: 20_000 }]
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
        [{ age: 95, total_balance: 15_000 }]
      end

      it "fails because total balance is less than the success threshold" do
        expect(evaluator.evaluate).to eq(
          success: false,
          explanation: "Simulation failed. Max age reached, but total balance of $15,000.00 " \
                       "is below success threshold of $20,000.00.",
          withdrawal_rate: 0.02
        )
      end
    end
  end

  describe "evaluating with different success factors" do
    context "when success factor is 1.5 and balance is sufficient" do
      let(:app_config) { AppConfig.new(File.join(base_fixture_path, "evaluator_input_success_factor_1_5.yml")) }
      let(:simulation_results) do
        [{ age: 95, total_balance: 45_000 }]
      end

      it "is successful if total balance meets or exceeds threshold" do
        expect(evaluator.evaluate).to eq(
          success: true,
          explanation: "Simulation successful with total balance of $45,000.00.",
          withdrawal_rate: 0.02
        )
      end
    end

    context "when success factor is 1.5 and balance is insufficient" do
      let(:app_config) { AppConfig.new(File.join(base_fixture_path, "evaluator_input_success_factor_1_5.yml")) }
      let(:simulation_results) do
        [{ age: 95, total_balance: 21_000 }]
      end

      it "fails because total balance is below threshold" do
        expect(evaluator.evaluate).to eq(
          success: false,
          explanation: "Simulation failed. Max age reached, but total balance of $21,000.00 " \
                       "is below success threshold of $30,000.00.",
          withdrawal_rate: 0.02
        )
      end
    end
  end
end

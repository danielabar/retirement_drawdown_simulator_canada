# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe Simulation::SimulatorFormatter do
  let(:base_fixture_path) { File.expand_path("../../fixtures", __dir__) }
  let(:app_config) { AppConfig.new(File.join(base_fixture_path, "example_input_minimal.yml")) }

  let(:expected_output) do
    <<~OUTPUT
      === First-Year Cash Flow Breakdown ===
      Desired Income Including TFSA Contribution: $30,010.00
      RRSP Withholding Tax: $10,140.00
      Expected Tax Refund: $6,427.00
      RRSP Available After Withholding: $23,660.00
      Required Cash Buffer for First Year: $6,350.00
      #{'-' * 150}
      Age        RRSP                 TFSA                 Taxable              Cash Cushion         Total Balance        Note                        RoR
      #{'-' * 150}
      65         $46,662.00           $30,310.10           $60,600.00           $0.00                $137,572.10          rrsp                       1.0%
      66         $12,990.62           $30,623.30           $61,206.00           $0.00                $104,819.92          rrsp                       1.0%
      67         $13,120.53           $30,939.63           $31,507.96           $0.00                $75,568.12           taxable                    1.0%
      68         $13,251.73           $31,259.13           $1,512.94            $0.00                $46,023.80           taxable                    1.0%
      69         $13,384.25           $1,271.72            $1,528.07            $0.00                $16,184.04           tfsa                       1.0%
      #{'-' * 150}
      Simulation Result: Failure
      Simulation failed. Max age 75 not reached. Final age is 69.
    OUTPUT
  end

  it "prints exactly the expected output" do
    simulation_results = Simulation::Simulator.new(app_config).run
    evaluator_results = Simulation::SimulationEvaluator.new(simulation_results, app_config).evaluate
    first_year_cash_flow_results = FirstYearCashFlow.new(app_config).calculate
    simulator_formatter = described_class.new(simulation_results, first_year_cash_flow_results,
                                              evaluator_results)

    expect { simulator_formatter.print_all }.to output(expected_output).to_stdout
  end
end

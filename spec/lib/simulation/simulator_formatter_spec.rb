# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe Simulation::SimulatorFormatter do
  let(:base_fixture_path) { File.expand_path("../../fixtures", __dir__) }
  let(:app_config) { AppConfig.new(File.join(base_fixture_path, "example_input_minimal.yml")) }

  let(:expected_output) do
    <<~OUTPUT
      === First-Year Cash Flow Breakdown ===
      Desired Income Including TFSA Contribution: $30,010.00
      RRSP Withdrawal Amount (higher due to income tax): $33,704.73
      RRSP Withholding Tax: $10,111.42
      Actual Tax Bill: $3,694.72
      Expected Tax Refund: $6,416.70
      RRSP Available After Withholding: $23,593.31
      Required Cash Buffer for First Year: $6,416.69
      #{'-' * 150}
      Age        RRSP                 TFSA                 Taxable              Cash Cushion         Total Balance        Note                        RoR
      #{'-' * 150}
      65         $46,758.22           $30,310.10           $60,600.00           $0.00                $137,668.32          rrsp                       1.0%
      66         $13,184.03           $30,623.30           $61,206.00           $0.00                $105,013.33          rrsp                       1.0%
      67         $13,315.87           $30,939.63           $31,507.96           $0.00                $75,763.46           taxable                    1.0%
      68         $13,449.03           $31,259.13           $1,512.94            $0.00                $46,221.10           taxable                    1.0%
      69         $13,583.52           $1,271.72            $1,528.07            $0.00                $16,383.31           tfsa                       1.0%
      #{'-' * 150}
      Simulation Result: Failure
      Simulation failed. Max age 75 not reached. Final age is 69.
      Withdrawal Rate: 17.65%
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

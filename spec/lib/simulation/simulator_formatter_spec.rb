# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe Simulation::SimulatorFormatter do
  let(:app_config) do
    AppConfig.new(
      "retirement_age" => 65,
      "max_age" => 75,
      "province_code" => "ONT",
      "annual_tfsa_contribution" => 10,
      "desired_spending" => 30_000,
      "annual_growth_rate" => {
        "average" => 0.01,
        "min" => -0.1,
        "max" => 0.1,
        "downturn_threshold" => -0.1
      },
      "return_sequence_type" => "constant",
      "accounts" => {
        "rrsp" => 80_000,
        "taxable" => 60_000,
        "tfsa" => 30_000,
        "cash_cushion" => 0
      },
      "cpp" => {
        "start_age" => 65,
        "monthly_amount" => 0
      },
      "taxes" => {
        "rrsp_withholding_rate" => 0.3
      }
    )
  end

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
      #{'-' * 160}
      Age        RRSP                 TFSA                 Taxable              Cash Cushion         CPP Used   Total Balance        Note                        RoR
      #{'-' * 160}
      65         $46,758.22           $30,310.10           $60,600.00           $0.00                No         $137,668.32          rrsp                       1.0%
      66         $13,184.03           $30,623.30           $61,206.00           $0.00                No         $105,013.33          rrsp                       1.0%
      67         $13,315.87           $30,939.63           $31,507.96           $0.00                No         $75,763.46           taxable                    1.0%
      68         $13,449.03           $31,259.13           $1,512.94            $0.00                No         $46,221.10           taxable                    1.0%
      69         $13,583.52           $1,271.72            $1,528.07            $0.00                No         $16,383.31           tfsa                       1.0%
      #{'-' * 160}
      Simulation Result: ❌ Failure
      Simulation failed. Max age 75 not reached. Final age is 69.
      Withdrawal Rate: 17.65%
    OUTPUT
  end

  it "prints exactly the expected output" do
    simulation_output = Simulation::Simulator.new(app_config).run
    evaluator_results = Simulation::SimulationEvaluator.new(simulation_output[:yearly_results], app_config).evaluate
    first_year_cash_flow_results = FirstYearCashFlow.new(app_config).calculate
    simulator_formatter = described_class.new(simulation_output, first_year_cash_flow_results, evaluator_results,
                                              visual: false)

    # temp debug
    simulator_formatter.print_all

    expect { simulator_formatter.print_all }.to output(expected_output).to_stdout
  end
end

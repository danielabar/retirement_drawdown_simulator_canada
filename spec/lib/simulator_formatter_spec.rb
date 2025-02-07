# frozen_string_literal: true

RSpec.describe SimulatorFormatter do
  subject(:simulator_formatter) { described_class.new(simulation_results, first_year_cash_flow_results) }

  let(:config_path) { File.join(__dir__, "..", "fixtures", "example_input_minimal.yml") }
  let(:plan) { RetirementPlan.new(config_path) }
  let(:simulation_results) { Simulator.new(plan).run }
  let(:first_year_cash_flow_results) { FirstYearCashFlow.new(plan).calculate }

  it "prints exactly the expected output" do
    expected_output = <<~OUTPUT
      === First-Year Cash Flow Breakdown ===
      Desired Income Including TFSA Contribution: $30,010.00
      RRSP Withholding Tax: $10,140.00
      Expected Tax Refund: $6,427.00
      RRSP Available After Withholding: $23,660.00
      Required Cash Buffer for First Year: $6,350.00
      #{'-' * 110}
      Age        RRSP                 TFSA                 Taxable              Note                        RoR
      #{'-' * 110}
      65         $46,662.00           $30,310.10           $60,600.00           RRSP Drawdown              1.0%
      66         $12,990.62           $30,623.30           $61,206.00           RRSP Drawdown              1.0%
      67         $13,120.53           $30,939.63           $31,507.96           Taxable Drawdown           1.0%
      68         $13,251.73           $31,259.13           $1,512.94            Taxable Drawdown           1.0%
      69         $13,384.25           $1,271.72            $1,528.07            TFSA Drawdown              1.0%
    OUTPUT

    expect { simulator_formatter.print_all }.to output(expected_output).to_stdout
  end
end

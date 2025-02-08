# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe SimulatorFormatter do
  subject(:simulator_formatter) { described_class.new(simulation_results, first_year_cash_flow_results) }

  let(:app_config) { AppConfig.new(File.join(__dir__, "..", "fixtures", "example_input_minimal.yml")) }
  let(:simulation_results) { Simulator.new(app_config).run }
  let(:first_year_cash_flow_results) { FirstYearCashFlow.new(app_config).calculate }

  it "prints exactly the expected output" do
    expected_output = <<~OUTPUT
      === First-Year Cash Flow Breakdown ===
      Desired Income Including TFSA Contribution: $30,010.00
      RRSP Withholding Tax: $10,140.00
      Expected Tax Refund: $6,427.00
      RRSP Available After Withholding: $23,660.00
      Required Cash Buffer for First Year: $6,350.00
      #{'-' * 130}
      Age        RRSP                 TFSA                 Taxable              Total Balance        Note                        RoR
      #{'-' * 130}
      65         $46,662.00           $30,310.10           $60,600.00           $137,572.10          RRSP Drawdown              1.0%
      66         $12,990.62           $30,623.30           $61,206.00           $104,819.92          RRSP Drawdown              1.0%
      67         $13,120.53           $30,939.63           $31,507.96           $75,568.12           Taxable Drawdown           1.0%
      68         $13,251.73           $31,259.13           $1,512.94            $46,023.80           Taxable Drawdown           1.0%
      69         $13,384.25           $1,271.72            $1,528.07            $16,184.04           TFSA Drawdown              1.0%
    OUTPUT

    expect { simulator_formatter.print_all }.to output(expected_output).to_stdout
  end
end

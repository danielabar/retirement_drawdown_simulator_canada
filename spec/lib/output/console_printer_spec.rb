# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe Output::ConsolePrinter do
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

  let(:expected_ages) { [65, 66, 67, 68, 69] }
  let(:expected_rate_of_returns) { [0.01, 0.01, 0.01, 0.01, 0.01] }
  let(:expected_total_balances) { [137_668.32, 105_013.33, 75_741.17, 46_198.58, 16_360.57] }

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
      #{'-' * 180}
      Age        RRSP                 TFSA                 Taxable              Cash Cushion         CPP Used   Total Balance        RRIF Excess          Note                        RoR
      #{'-' * 180}
      65         $46,758.22           $30,310.10           $60,600.00           $0.00                No         $137,668.32          $0.00                rrsp                       1.0%
      66         $13,184.03           $30,623.30           $61,206.00           $0.00                No         $105,013.33          $0.00                rrsp                       1.0%
      67         $0.00                $30,939.63           $44,801.54           $0.00                No         $75,741.17           $0.00                rrsp, taxable              1.0%
      68         $0.00                $31,259.13           $14,939.45           $0.00                No         $46,198.58           $0.00                taxable                    1.0%
      69         $0.00                $16,360.57           $0.00                $0.00                No         $16,360.57           $0.00                taxable, tfsa              1.0%
      #{'-' * 180}
      Simulation Result: ❌ Failure
      Simulation failed. Max age 75 not reached. Final age is 69.
      Withdrawal Rate: 17.65%
      Average Rate of Return: 1.0%
    OUTPUT
  end

  it "prints exactly the expected output without charts" do
    simulation_output = Simulation::Simulator.new(app_config).run
    evaluator_results = Simulation::SimulationEvaluator.new(simulation_output[:yearly_results], app_config).evaluate
    first_year_cash_flow_results = FirstYearCashFlow.new(app_config).calculate
    simulator_formatter = described_class.new(simulation_output, first_year_cash_flow_results, evaluator_results,
                                              visual: false)

    expect { simulator_formatter.print_all }.to output(expected_output).to_stdout
  end

  it "prints charts" do
    simulation_output = Simulation::Simulator.new(app_config).run
    evaluator_results = Simulation::SimulationEvaluator.new(simulation_output[:yearly_results], app_config).evaluate
    first_year_cash_flow_results = FirstYearCashFlow.new(app_config).calculate
    simulator_formatter = described_class.new(simulation_output, first_year_cash_flow_results, evaluator_results)

    allow(Output::ConsolePlotter).to receive(:plot_return_sequence)
    allow(Output::ConsolePlotter).to receive(:plot_total_balance)

    expect { simulator_formatter.print_all }.to output.to_stdout

    expect(Output::ConsolePlotter).to have_received(:plot_return_sequence).with(expected_ages, expected_rate_of_returns)
    expect(Output::ConsolePlotter).to have_received(:plot_total_balance) do |ages, balances|
      expect(ages).to eq(expected_ages)
      expected_total_balances.each_with_index do |expected_balance, index|
        expect(balances[index]).to be_within(0.01).of(expected_balance)
      end
    end
  end
end

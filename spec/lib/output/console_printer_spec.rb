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
      ┌───────────────────────────────────────────────────┬─────────┐
      │ Description                                       │  Amount │
      ├───────────────────────────────────────────────────┼─────────┤
      │ Desired Income Including TFSA Contribution        │ $30,010 │
      │ RRSP Withdrawal Amount (higher due to income tax) │ $33,705 │
      │ RRSP Withholding Tax                              │ $10,111 │
      │ Actual Tax Bill                                   │  $3,695 │
      │ Expected Tax Refund                               │  $6,417 │
      │ RRSP Available After Withholding                  │ $23,593 │
      │ Required Cash Buffer for First Year               │  $6,417 │
      └───────────────────────────────────────────────────┴─────────┘
      === Yearly Results ===
      ┌─────┬─────────┬─────────┬─────────┬──────────────┬──────────┬───────────────┬─────────────────┬───────────────┬──────┐
      │ Age │    RRSP │ Taxable │    TFSA │ Cash Cushion │ CPP Used │ Total Balance │ RRIF Net Excess │ Note          │  RoR │
      ├─────┼─────────┼─────────┼─────────┼──────────────┼──────────┼───────────────┼─────────────────┼───────────────┼──────┤
      │ 65  │ $46,758 │ $60,600 │ $30,310 │           $0 │ No       │      $137,668 │              $0 │ rrsp          │ 1.0% │
      │ 66  │ $13,184 │ $61,206 │ $30,623 │           $0 │ No       │      $105,013 │              $0 │ rrsp          │ 1.0% │
      │ 67  │      $0 │ $44,802 │ $30,940 │           $0 │ No       │       $75,741 │              $0 │ rrsp, taxable │ 1.0% │
      │ 68  │      $0 │ $14,939 │ $31,259 │           $0 │ No       │       $46,199 │              $0 │ taxable       │ 1.0% │
      │ 69  │      $0 │      $0 │ $16,361 │           $0 │ No       │       $16,361 │              $0 │ taxable, tfsa │ 1.0% │
      └─────┴─────────┴─────────┴─────────┴──────────────┴──────────┴───────────────┴─────────────────┴───────────────┴──────┘
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

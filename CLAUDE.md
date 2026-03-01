# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```sh
ruby main.rb                                          # detailed mode, reads inputs.yml
ruby main.rb success_rate                             # success_rate mode, reads inputs.yml
ruby main.rb demo/four_percent_rule.yml               # custom file, mode from YAML or defaults to detailed
ruby main.rb success_rate demo/four_percent_rule.yml  # success_rate mode, custom file (order doesn't matter)
bin/rspec                     # Run all tests
bin/rspec spec/lib/tax/income_tax_calculator_spec.rb  # Run a single spec file
bin/rubocop                   # Lint
bin/ci                        # Run rubocop + rspec + both main.rb modes
bin/console                   # Start IRB with app loaded (prompt: drawdown_simulator>); use reload! to restart
```

The `inputs.yml` file (gitignored) holds user financial inputs. Copy from `inputs.yml.template` to create it.

## Architecture

### Entry point and run modes

`main.rb` → `Run::AppRunner` reads the inputs file and dispatches to either `Run::SimulationDetailed` or `Run::SuccessRateSimulation`. The inputs file defaults to `inputs.yml`; pass any `.yml` path as a CLI argument to override. Mode is detected from a `detailed`/`success_rate` argument, falling back to the `mode` key in the inputs file, then `"detailed"`.

### Simulation loop

`Simulation::Simulator` is the core loop. For each age from `retirement_age` to `max_age`:
1. Get market return from `ReturnSequences::SequenceSelector` (picks `constant`, `mean`, or `geometric_brownian_motion`)
2. Ask `Strategy::RrspToTaxableToTfsa` to plan withdrawals — uses cash cushion if market return is below `downturn_threshold`, otherwise delegates to `Strategy::WithdrawalPlanner`
3. Apply transactions and growth to all accounts
4. Record results

`Simulation::SimulationEvaluator` checks if the run reached `max_age` with at least `success_factor * desired_spending` remaining.

### Withdrawal strategy

`Strategy::WithdrawalPlanner` handles the RRSP → Taxable → TFSA ordering:
- **RRSP**: requires a *reverse* tax calculation to determine the gross withdrawal needed to achieve desired after-tax spending. If CPP is active, uses binary search to find the right RRSP amount (since both RRSP withdrawals and CPP are taxable income and interact non-linearly).
- **RRIF**: mandatory minimum withdrawals start at age 71 (`config/rrif.yml`). If the mandatory amount exceeds desired withdrawal, the after-tax excess is deposited into the taxable account.
- Taxable and TFSA withdrawals are at face value (no extra tax modelling currently).
- Optional TFSA contributions during RRSP/taxable drawdown phase are skipped when drawing from cash cushion or TFSA.

`WithdrawalAmounts` centralises per-account withdrawal amount calculation, including CPP offset logic.

### Tax calculations

- `Tax::IncomeTaxCalculator` — forward: gross income → federal + provincial tax + take-home
- `Tax::ReverseIncomeTaxCalculator` — reverse: desired take-home → gross income needed
- Tax brackets/rates live in `config/tax.yml` (production) and `config/tax_fixed.yml` (tests, for determinism)
- `ENV["APP_ENV"] = "test"` switches the tax files; set automatically by `spec/spec_helper.rb`
- Province codes: ONT, NL, PE, NS, NB, MB, SK, AB, BC, YT, NT, NU

### Config

`AppConfig` wraps the YAML inputs file and provides typed accessors (`accounts`, `cpp`, `taxes`, `annual_growth_rate`). RRIF rates live in `config/rrif.yml` (`config/rrif_fixed.yml` for tests).

### Testing conventions

- Fixtures in `spec/fixtures/` are YAML files used as `AppConfig` inputs for integration-style specs
- Tax tests always use fixed rates via the `APP_ENV=test` switch
- `lib/run/` is excluded from SimpleCov coverage

# Architecture

This document describes how the code is structured — the modules, classes, and how they connect. It's intended for contributors, or anyone who wants to extend the simulator or understand why a number came out the way it did by tracing the code path.

For a description of the *financial* mechanics (what RRIF is, how CPP interacts with tax, what GBM does), see [How It Works](how-it-works.md).

---

## Directory Structure

```
lib/
  run/                    # Entry points for each run mode
  simulation/             # Core simulation loop and success evaluator
  strategy/               # Withdrawal planning and account selection
  tax/                    # Forward and reverse income tax calculations
  return_sequences/       # Market return generators (constant, mean, GBM, recorded)
  failed_runs/            # Capture machinery for failed success_rate runs
  output/                 # Console printing and formatting
  account.rb              # Account model (balance, withdraw, deposit, grow)
  app_config.rb           # Typed wrapper around inputs.yml
  inputs_digest.rb        # Stable hash of replay-relevant inputs
  withdrawal_amounts.rb   # Per-account withdrawal amount calculations
  withdrawal_rate_calculator.rb
  first_year_cash_flow.rb
  success_rate_results.rb
  numeric_formatter.rb
config/
  tax.yml                 # Current-year federal and provincial tax brackets
  tax_fixed.yml           # Fixed tax config used in tests (deterministic)
  rrif.yml                # CRA prescribed RRIF withdrawal factors by age
  rrif_fixed.yml          # Fixed RRIF config used in tests
failed_runs/              # Captured failed sequences from success_rate mode (gitignored)
spec/                     # RSpec tests
  fixtures/               # YAML files used as AppConfig inputs in specs
```

---

## Execution Flow

```mermaid
flowchart TD
    A[main.rb] --> B[AppRunner]
    B -->|mode: detailed| C[SimulationDetailed]
    B -->|mode: success_rate| D[SuccessRateSimulation]

    C --> E[Simulator]
    C --> F[FirstYearCashFlow]
    C --> G[SimulationEvaluator]
    C --> H[ConsolePrinter]

    D -->|runs N times| E
    D --> G
    D --> I[SuccessRatePrinter]

    E --> J[SequenceSelector]
    E --> K[RrspToTaxableToTfsa]

    J --> L[ConstantReturnSequence]
    J --> M[MeanReturnSequence]
    J --> N[GeometricBrownianMotionSequence]

    K --> O[WithdrawalAmounts]
    K --> P[WithdrawalPlanner]

    O --> Q[ReverseIncomeTaxCalculator]
    O --> R[IncomeTaxCalculator]
    P --> R
    P --> S[RRIFWithdrawalCalculator]
```

---

## Components

### Entry Points — `lib/run/`

**`AppRunner`** reads `inputs.yml`, resolves the run mode (`detailed` or `success_rate`), and delegates to the appropriate run class. The mode can be overridden via `ARGV[0]` (used by the `ruby main.rb success_rate` command). Validation: `mode: success_rate` combined with `return_sequence_type: recorded` errors at startup, since a deterministic sequence run N times would produce N identical results.

**`SimulationDetailed`** orchestrates a single run: creates a `Simulator`, runs it, feeds the results to `SimulationEvaluator` and `FirstYearCashFlow`, then prints everything via `ConsolePrinter`.

**`SuccessRateSimulation`** runs `Simulator` N times (default 500), collects `{success, withdrawal_rate, final_balance}` from each, aggregates into `SuccessRateResults`, and prints via `SuccessRatePrinter`. It also drives the `FailedRuns::Writer`: prepares the `failed_runs/` directory before the loop, offers each failed run to a reservoir sampler, and flushes the kept runs (plus a manifest) at the end.

---

### Simulation Loop — `lib/simulation/`

**`Simulator`** is the core loop. On initialization it builds a `ReturnSequences::SequenceSelector` (to get market returns) and a `Strategy::RrspToTaxableToTfsa` (to manage accounts and withdrawals). For each age from `retirement_age` to `max_age`:

1. Set current age on the strategy
2. Ask `SequenceSelector` for this year's market return
3. Ask the strategy to `select_account_transactions(market_return)` — returns an array of `{account:, amount:, forced_net_excess:}` hashes, or empty array if funds are exhausted
4. Call `strategy.transact(account_transactions)` to apply the withdrawals
5. Call `strategy.apply_growth(market_return)` to grow all account balances
6. Record the yearly snapshot

The loop breaks early (returning a truncated results array) if `select_account_transactions` returns empty — this is the "ran out of money" signal.

**`SimulationEvaluator`** takes the yearly results array and determines success or failure. A run succeeds if the last recorded age equals `max_age` *and* the final total balance is at least `success_factor × desired_spending`. If the loop broke early (money ran out before `max_age`), the run fails.

---

### Withdrawal Strategy — `lib/strategy/`

**`RrspToTaxableToTfsa`** is the top-level strategy. It owns the four `Account` instances (rrsp, taxable, tfsa, cash_cushion) and a `WithdrawalAmounts` instance. Each year it decides whether to withdraw from the cash cushion or from investment accounts:

- **Annuity purchase:** when `current_age` is set to the annuity's `purchase_age`, the lump sum is withdrawn from the RRSP before any withdrawal planning — unless the RRSP balance is insufficient, in which case the purchase is skipped and the simulation continues without annuity income. This is a one-time event — subsequent years just receive the annuity income (if purchased).
- **Cash cushion path:** if `market_return < downturn_threshold` and the cash cushion has enough balance *and* no mandatory RRIF withdrawal is required, it returns a single cash cushion transaction.
- **Normal path:** delegates to `WithdrawalPlanner` to plan investment account withdrawals.

After `transact` applies withdrawals, it handles the optional TFSA contribution deposit (skipped if the cash cushion or TFSA was used).

**`WithdrawalPlanner`** plans withdrawals from investment accounts in RRSP → Taxable → TFSA order. It attempts the plan twice if the TFSA gets touched: first with TFSA contributions included, then again without (to preserve the TFSA). If all accounts are still insufficient, it returns an empty array.

For RRSP withdrawals specifically, it handles two cases:
- **RRIF mandatory withdrawal exceeds desired withdrawal:** the mandatory amount becomes the actual gross; the after-tax excess over desired spending is recorded as `forced_net_excess` and later deposited into the taxable account.
- **RRSP partially funded:** drains the RRSP entirely and calculates the after-tax proceeds, then passes the remaining shortfall to the taxable account.

**`RRIFWithdrawalCalculator`** looks up the CRA-prescribed minimum withdrawal percentage for a given age from `config/rrif.yml` and computes the mandatory dollar amount from the current RRSP balance. Returns 0 for ages below 71.

---

### Withdrawal Amounts — `lib/withdrawal_amounts.rb`

`WithdrawalAmounts` calculates how much to withdraw from each account type, given the current age, desired spending, and whether CPP, OAS, or annuity income is active. The `annuity_used?` method requires both the config checks (monthly_payment > 0, current_age >= purchase_age) AND an `annuity_active` flag set by the strategy after a successful purchase. This prevents the withdrawal math from subtracting annuity income when the purchase was skipped due to insufficient RRSP balance. This is where the per-account math lives:

- **`annual_rrsp`:** calls `ReverseIncomeTaxCalculator` to find the gross RRSP withdrawal needed to net the desired spending. If CPP, OAS, or annuity income is active, runs binary search (see below) because these income sources and RRSP withdrawals interact in the tax calculation.
- **`annual_taxable` / `annual_tfsa` / `annual_cash_cushion`:** desired spending minus net income from CPP, OAS, and annuity (whichever are active), since taxable/TFSA/cash withdrawals aren't taxed further.

**Binary search:** when CPP, OAS, or annuity income is active, the combined taxable income is `rrsp_withdrawal + cpp_gross + oas_gross + annuity_gross`. Binary search bounds: upper = gross RRSP needed without any other income; lower = upper minus total other gross income. Converges to within $1 in under 100 iterations.

---

### Tax — `lib/tax/`

**`IncomeTaxCalculator`** — forward calculation. Given gross income and a province code, applies progressive federal and provincial brackets with the basic personal amount exemption as a non-refundable credit. Returns `{federal_tax:, provincial_tax:, total_tax:, take_home:}`.

**`ReverseIncomeTaxCalculator`** — reverse calculation. Given desired take-home and a province code, finds the gross income via binary search (bounds: `desired_take_home` to `desired_take_home × 1.5`, tolerance $0.01). Uses the same progressive bracket logic internally.

Both calculators load from `config/tax.yml` in production, or `config/tax_fixed.yml` when `ENV["APP_ENV"] == "test"` — allowing tests to use stable, known rates rather than rates that change each tax year.

---

### Return Sequences — `lib/return_sequences/`

**`SequenceSelector`** reads the `return_sequence_type` config key and instantiates the appropriate class. All sequences receive `retirement_age`, `max_age`, `average`, `min`, and `max` on initialization and respond to `get_return_for_age(age)`.

**`ConstantReturnSequence`** — returns `average` every year.

**`MeanReturnSequence`** — generates a random sequence pre-shuffled to average out to the target over the full simulation.

**`GeometricBrownianMotionSequence`** — generates an independent random return each year. Each return is `exp(drift + sigma × shock) - 1` where:
- `drift` = `log(1 + average) - 0.5 × sigma²` (Itô correction to prevent drift above intended average)
- `sigma` = derived from `min`/`max` via three-sigma rule: `(max - min) / 6`
- `shock` = drawn from a Student-t distribution (df=10) for fat tails

**`RecordedSequence`** — loads a previously-saved `{age => return}` map from disk instead of generating one. Used by detailed mode to replay a failed run captured by `success_rate` mode. Exposes the saved summary and inputs digest so `SimulationDetailed` can announce the replay and warn on digest mismatch.

---

### Failed Runs Capture — `lib/failed_runs/`

**`ReservoirSampler`** — generic K-of-N reservoir (Algorithm R). Streaming-with-unknown-N selection so every failure that ever occurred has equal probability `K / total_seen` of ending up in the saved set, regardless of when it streamed past.

**`Serializer`** — read/write for the per-run YAML schema (`id`, `captured_at`, `inputs_digest`, `outcome`, `return_sequence`).

**`Manifest`** — writes `failed_runs/index.md`: header, capture timestamp, source digest, and one bullet per saved run with its summary.

**`Writer`** — orchestrator. `prepare!` wipes prior `run_*.yml` and `index.md` (preserves `.gitkeep`); `offer(simulation_output, evaluator_results)` builds a payload from a single run and feeds it to the reservoir; `flush!` writes each kept payload to `run_NNNN.yml` and writes the manifest. Capacity hardcoded to 50.

**`InputsDigest`** (in `lib/inputs_digest.rb`) — SHA256 over the *replay-relevant* subset of inputs: those that affect outcome when the return sequence is fixed. Excludes `mode`, `total_runs`, `return_sequence_type`, `recorded_sequence_file`, and the GBM/mean parameters (`average`/`min`/`max`) since the sequence comes from disk.

---

### Output — `lib/output/`

**`ConsolePrinter`** formats and prints the detailed run: summary header, first-year cash flow analysis, the year-by-year table, and the evaluator verdict.

**`SuccessRatePrinter`** formats the Monte Carlo summary: success rate percentage, average final balance, and the percentile distribution table.

**`ConsolePlotter`** renders small ASCII sparkline-style charts used in some output views.

---

### Support Classes

**`Account`** holds a balance and supports `withdraw(amount)`, `deposit(amount)`, and `apply_growth(rate)`. Cash cushion accounts use a separate savings rate rather than the market return.

**`AppConfig`** wraps the `inputs.yml` hash with typed accessors (`accounts`, `cpp`, `oas`, `annuity`, `taxes`, `annual_growth_rate`). Accepts either a file path string or a hash directly (used in tests to pass fixture hashes inline).

**`FirstYearCashFlow`** calculates the withholding tax gap in the first year of RRSP withdrawals — the difference between what the bank withholds (30%) and what you'll actually owe (~15%), and the expected refund timing.

**`SuccessRateResults`** aggregates an array of per-run results and computes success rate, mean final balance, and percentile breakdowns.

**`WithdrawalRateCalculator`** computes the initial withdrawal rate (desired spending / total starting balance) for display purposes.

---

## Config Files

| File | Purpose |
|---|---|
| `config/tax.yml` | Current-year federal and provincial tax brackets, rates, and basic personal amount exemptions |
| `config/tax_fixed.yml` | Frozen tax config used in tests for determinism |
| `config/rrif.yml` | CRA-prescribed minimum RRIF withdrawal factors by age (71–95+) |
| `config/rrif_fixed.yml` | Frozen RRIF config used in tests |
| `inputs.yml` | User's financial inputs (gitignored; copy from `inputs.yml.template`) |

---

## Testing

Tests live in `spec/`. Run them with `bin/rspec`.

- **Unit tests** test individual calculators in isolation. Tax tests use `APP_ENV=test` (set automatically by `spec/spec_helper.rb`) to switch to `tax_fixed.yml` / `rrif_fixed.yml` so results don't change when tax brackets are updated.
- **Integration-style specs** use YAML fixtures in `spec/fixtures/` as `AppConfig` inputs.
- **`lib/run/`** is excluded from SimpleCov coverage (thin orchestration layer, tested end-to-end by `bin/ci` which runs both `main.rb` modes).
- **`bin/ci`** runs rubocop + rspec + both `main.rb` invocations as the full local CI check.

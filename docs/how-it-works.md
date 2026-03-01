# How It Works

This document explains the mechanics behind the simulation — what happens under the hood at each step, and why certain design choices were made. If you want to understand why the numbers come out the way they do, or verify that the simulator is handling your situation correctly, this is the place to start.

---

## Withdrawal Order: RRSP → Taxable → TFSA

Each year of the simulation, the simulator determines how much to withdraw and from which accounts, in this fixed order:

1. **RRSP first** — because RRSP withdrawals are taxable income, drawing it down early (while you may still be in a lower bracket) can be advantageous. Once you turn 71 the government forces minimum withdrawals anyway (see [RRIF Mandatory Withdrawals](#rrif-mandatory-withdrawals) below).
2. **Taxable account second** — once the RRSP is exhausted, withdrawals come from the taxable account. Currently the simulator does not model capital gains tax on these withdrawals (see [Limitations](#limitations)).
3. **TFSA last** — TFSA withdrawals are tax-free, so the simulator preserves this account as long as possible to maximize the tax-free compounding benefit.

If one account doesn't have quite enough to cover the full year's spending, the simulator automatically combines it with the next account in the sequence. For example, if the RRSP has $20,000 left but you need $46,000 after tax, it withdraws the full $20,000 gross from the RRSP — but after income tax that might only net $17,500 — and then takes the remaining shortfall (roughly $28,500) from the taxable account.

### Optional TFSA Contributions During Drawdown

You can configure the simulator to make annual TFSA contributions during the RRSP and taxable drawdown phases (set `annual_tfsa_contribution` to a non-zero value). The idea is to shift future income from taxable accounts to the tax-free TFSA while you still have registered and taxable funds to draw on.

When this is enabled, the withdrawal amount is increased to cover both your desired spending *and* the TFSA contribution, regardless of which account is being drawn from:

- **RRSP phase:** the gross RRSP withdrawal is increased to cover spending plus the TFSA contribution (both come from the pre-tax RRSP amount)
- **Taxable phase:** the taxable withdrawal is similarly increased to cover spending plus the TFSA contribution

TFSA contributions are automatically skipped in two situations:
- When the simulator is drawing from the cash cushion (a downturn year — no point depositing into TFSA when you're trying to conserve investments)
- When the TFSA itself is being withdrawn from (the simulator retries the whole withdrawal plan without the contribution in this case)

---

## Tax Engine

### The problem most calculators ignore

The most common mistake in DIY retirement calculators is treating RRSP withdrawals as if the full withdrawal becomes spending money. It doesn't — RRSP withdrawals are counted as regular income and taxed accordingly. If you want $40,000 to spend, you have to withdraw significantly more than $40,000.

**Example (Ontario, 2025 rates):** To end up with $40,000 after tax, you need to withdraw approximately $46,200 from your RRSP. That's 15.5% more than your target spending. Over a 20-year retirement, ignoring this leads to a substantial shortfall.

### Forward and reverse tax calculations

The simulator includes two tax calculators:

**Forward (gross → take-home):** Given a gross withdrawal amount, calculate federal tax, provincial tax, and take-home pay. Used when the RRSP is being drained and the simulator needs to know what the after-tax proceeds are.

**Reverse (take-home → gross):** Given your desired after-tax spending, calculate what gross RRSP withdrawal is needed. This uses binary search to find the gross income where the tax calculation returns your target. This is what lets the simulator correctly answer "how much do I actually need to withdraw?"

Binary search is necessary here because the tax system is piecewise linear — different rates apply at different income brackets — so there is no clean algebraic inverse. Going forward (gross → take-home) is straightforward: march through the brackets and apply each rate. Going backward, you don't know in advance which brackets the gross income will span, and writing an algebraic inverse for every possible combination of bracket crossings would be complex and brittle.

Binary search sidesteps this by exploiting one simple property: the forward function is monotonically increasing — more gross always produces more take-home. So the reverse calculator starts with a lower bound (`desired_take_home`) and an upper bound (`desired_take_home × 1.5`), tries the midpoint by running it through the forward calculator, adjusts the bounds based on whether the result was too high or too low, and repeats until the gap is under $0.01. No need to reason about bracket boundaries in reverse — just keep calling the forward calculator until it converges.

Both calculators use progressive federal and provincial tax brackets with the basic personal amount exemption applied as a non-refundable tax credit.

### Provinces and territories supported

All provinces and territories are supported except Quebec:

**ONT, NL, PE, NS, NB, MB, SK, AB, BC, YT, NT, NU**

Quebec is out of scope. Quebec residents contribute to the Quebec Pension Plan (QPP) instead of CPP, Quebec has its own provincial abatement on federal tax, and its basic personal amount structure differs enough that supporting it would require a near-complete parallel implementation.

---

## CPP Interaction

CPP income is taxable — it counts as regular income just like an RRSP withdrawal. This creates a non-linear interaction that most calculators get wrong.

### Why you can't just subtract CPP from your spending needs

Suppose you want $40,000 after tax, and CPP pays you $18,000/year gross. You might think: "I only need $22,000 from my RRSP." But that's wrong, because when you add the $18,000 CPP to the RRSP withdrawal, the combined income pushes you into a higher tax bracket. The combined tax on $22,000 RRSP + $18,000 CPP is higher than the tax on $18,000 CPP alone.

### Binary search

The simulator solves this correctly using binary search. It starts with two bounds:

- **Upper bound:** the RRSP withdrawal you'd need if you had no CPP at all
- **Lower bound:** the upper bound minus the full gross CPP amount (the most you could possibly reduce it)

It then repeatedly tries the midpoint: "if I withdraw this much from my RRSP, add CPP, and calculate tax on the combined income, do I end up with my desired spending?" It narrows the range until the result is within $1 of the target.

This means the simulator correctly accounts for the fact that higher RRSP withdrawals push CPP income through higher marginal rates, and vice versa.

### CPP start age

You configure `cpp.start_age` in `inputs.yml`. Before that age, CPP is zero and the simulator withdraws the full amount from investment accounts. Once you reach that age, CPP reduces your required withdrawals each year for the rest of the simulation.

The My Service Canada estimate assumes you keep working until you take CPP. If you're retiring earlier, use the [PWL Capital CPP calculator](https://research-tools.pwlcapital.com/research/cpp) to get a more realistic estimate of what you'd actually receive after years of no contributions.

---

## RRIF Mandatory Withdrawals

### What is a RRIF?

The government does not let you hold an RRSP indefinitely. By December 31 of the year you turn 71, your RRSP must be converted to a Registered Retirement Income Fund (RRIF). From that point forward, you must withdraw a minimum percentage of the RRIF balance each year. The percentage is set by CRA and increases with age. The rates below are from the 2025 tax year — check the [CRA prescribed factors table](https://www.canada.ca/en/revenue-agency/services/tax/businesses/topics/completing-slips-summaries/t4rsp-t4rif-information-returns/payments/chart-prescribed-factors.html) for the most current values:

| Age | Minimum withdrawal rate |
| --- | ----------------------- |
| 71  | 5.28%                   |
| 72  | 5.40%                   |
| 73  | 5.53%                   |
| 74  | 5.67%                   |
| 75  | 5.82%                   |
| 76  | 5.98%                   |
| 77  | 6.17%                   |
| 78  | 6.36%                   |
| 79  | 6.58%                   |
| 80  | 6.82%                   |
| 81  | 7.08%                   |
| 82  | 7.38%                   |
| 83  | 7.71%                   |
| 84  | 8.08%                   |
| 85  | 8.51%                   |
| 86  | 8.99%                   |
| 87  | 9.55%                   |
| 88  | 10.21%                  |
| 89  | 10.99%                  |
| 90  | 11.92%                  |
| 91  | 13.06%                  |
| 92  | 14.49%                  |
| 93  | 16.34%                  |
| 94  | 18.79%                  |
| 95+ | 20.00%                  |

Source: [CRA prescribed factors](https://www.canada.ca/en/revenue-agency/services/tax/businesses/topics/completing-slips-summaries/t4rsp-t4rif-information-returns/payments/chart-prescribed-factors.html)

### How the simulator handles it

In most years, especially early in retirement when the RRSP is being drawn down aggressively, the mandatory minimum will be less than what the simulator would have withdrawn anyway — so it has no effect.

In some scenarios, particularly when strong market returns have grown the RRSP balance, the mandatory minimum may exceed what you'd otherwise want to withdraw. In that case:

- The simulator withdraws the mandatory amount (which counts as taxable income)
- It calculates the after-tax proceeds from that mandatory withdrawal
- The amount *in excess* of what you actually needed is deposited into the taxable account

The output table shows this as "RRIF Net Excess" — the after-tax surplus that ends up in your taxable account because the government forced you to take out more than you wanted. That excess still exists and keeps growing in the taxable account, but it's money you had to "unlock" on the government's schedule rather than your own.

### RRIF and CPP together

When both RRIF mandatory withdrawals and CPP are active, the simulator correctly treats both as taxable income in the combined calculation.

### Cash cushion and RRIF

One known limitation: if the market is in a downturn *and* a mandatory RRIF withdrawal is required, the simulator still withdraws from the RRSP (mandatory obligations take precedence). In this scenario the cash cushion is not used. This is noted in the [roadmap](roadmap.md) as a future improvement.

---

## Return Sequence Generators

How the market performs each year determines how long your money lasts — but it's not just the average that matters, it's the *order* of good and bad years. A severe crash in year 2 of retirement is far more damaging than the same crash in year 20, because in year 2 you're selling investments at their lowest to fund living expenses, leaving less capital to recover.

The simulator offers three generators for modeling annual returns:

### `constant`

Every year returns exactly the `average` you configured. Produces clean, predictable output that's easy to reason about, but completely unrealistic — markets don't do this. Useful for sanity-checking the model or understanding the mechanics, but not recommended for real planning.

### `mean`

Returns are random each year but constrained to average out to your configured target over the full simulation. Better than constant, but still avoids the harsh reality that some retirements begin with several bad years in a row. Not recommended for success rate mode.

### `geometric_brownian_motion` (recommended)

This is the realistic option. Each year gets an independently drawn return — mostly near the average, with occasional good years and bad years, including rare severe crashes. It's the recommended choice for success rate mode.

**How it works:** Each simulated year's return is generated from a drift term (your average return, adjusted for compounding math) plus a random shock drawn from a Student-t distribution. The Student-t has "fat tails" — meaning extreme years (like a -37% crash or a +45% boom) happen more often than a normal bell curve would predict. This better reflects how actual markets behave, where crashes occur more frequently than pure statistical theory would suggest.

**Volatility calibration:** The simulator derives the volatility parameter (sigma) from your configured `min` and `max` values using the three-sigma rule: the extremes should represent roughly the worst and best years you'd ever expect, and the spread between them determines how volatile the modeled returns are. This is why the `min` and `max` should represent genuine historical extremes for your investment type, not a comfortable or typical range.

**Itô correction:** A small mathematical adjustment is applied to prevent the average of many simulated runs from drifting above your intended average over time. Without it, compounding arithmetic would cause systematic upward bias.

**No mean reversion — by design:** Real markets tend to recover after crashes — cheap prices attract buyers and push returns back up. This model does not simulate that. Every year is drawn independently, with no memory of previous years. This means the model can generate extended bad stretches that real markets would typically recover from faster. The result is more conservative success rates than historical studies (like the original 4% rule research) produce for the same withdrawal rate. This is intentional: the goal is to stress-test your plan against futures that could be worse than history, not to reproduce historical outcomes.

---

## Cash Cushion

The cash cushion is a separate savings account (e.g. a HISA or GIC) that serves as a buffer during market downturns. When the simulated return for a year falls below your configured `downturn_threshold`, the simulator withdraws from the cash cushion instead of selling investments.

The logic is straightforward: avoid selling equities at a loss during a down year. The cash cushion earns a separate, lower interest rate (your `savings` rate) rather than the market return.

**When the cash cushion is used:**
- Market return falls below `downturn_threshold` (e.g. -10%)
- Cash cushion has enough balance to cover the full year's spending

**When the cash cushion is NOT used:**
- Market return is above the threshold (even if slightly negative)
- The cash cushion balance has been depleted
- A mandatory RRIF withdrawal is required that year (RRSP withdrawals are mandatory regardless)

The cash cushion is not refilled during the simulation — once it's spent, it's gone. The [roadmap](roadmap.md) notes an enhancement to refill it during strong return years.

---

## Limitations

A few simplifications are worth knowing about:

- **No inflation modeling.** The spending amount is fixed throughout — there is no built-in inflation adjustment. To preserve purchasing power, enter real (after-inflation) returns for `average`: e.g. if your portfolio returns 8% nominally and inflation is 3%, enter 0.05. If you enter nominal returns instead, spending will silently lose purchasing power over time, making results overly optimistic.
- **No capital gains tax on taxable account withdrawals.** Selling ETFs in a taxable account triggers capital gains, half of which is taxable income. For many retirees with broadly diversified ETFs and reinvested dividends, the gain per dollar sold may be small enough that it falls under the basic personal amount — but this isn't always true and the simulator doesn't model it.
- **No OAS.** Old Age Security is not yet modeled. It's on the [roadmap](roadmap.md).
- **All accounts invested in the same thing.** The simulator applies a single market return to all accounts each year. It doesn't model different asset allocations per account.
- **Quebec not supported.** See [Tax Engine](#tax-engine) above.

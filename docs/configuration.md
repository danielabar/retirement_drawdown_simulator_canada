# Configuration Reference

Your financial inputs are stored in `inputs.yml`. To create it, copy the template:

```sh
cp inputs.yml.template inputs.yml
```

Then open it in a text editor and replace the values with your actual financial information.

> [!WARNING]
> `inputs.yml` contains personal financial information and is excluded from Git (see `.gitignore`). Do not commit it.

---

## Full Reference

```yaml
# Mode can be 'detailed' for a single run with detailed output, or 'success_rate'
mode: detailed

# For success_rate mode
total_runs: 1000

# Age at which you plan to start retirement
retirement_age: 65

# Maximum age to run the simulation until.
# This prevents infinite loops if investment growth outpaces withdrawals.
# Choose a reasonable upper bound based on longevity estimates,
# but note that this is just for the simulation and not a personal prediction.
max_age: 95

# Province or territory where you reside
# Valid values are: ONT, NL, PE, NS, NB, MB, SK, AB, BC, YT, NT, NU
# Note: Quebec is not supported due to QPP and provincial tax differences.
province_code: ONT

# Success factor: defines the multiplier for total_balance needed by max_age for success.
# Supports fractional, eg: 1.5
success_factor: 1

# Growth rate settings for your portfolio.
# This simulation does not model inflation — your spending amount stays fixed throughout.
# To preserve purchasing power, enter real (after-inflation) returns rather than nominal.
# For example: if your portfolio returns 8% nominally and inflation is 3%, enter 0.05.
# If you enter nominal returns instead, spending will silently lose purchasing power over
# time, making results overly optimistic.
#
# average: the long-run average annual real return you expect from your portfolio.
#   Broad global equity index funds (e.g. XEQT, VEQT): ~0.05 to 0.07
#   Balanced 60/40 portfolio: ~0.03 to 0.05
#
# min and max: the historical extreme annual returns for your investment type.
#   These are NOT a typical range — they represent the worst and best single years
#   ever recorded. The simulation uses them to calibrate how volatile your returns are.
#   Setting them too narrow makes the simulation unrealistically calm.
#
#   100% global equity (e.g. XEQT, VEQT — all stocks, no bonds):
#     average: 0.05 to 0.07
#     min: -0.40  (a globally diversified portfolio fell ~40% in 2008; -45% figures
#                  are for US-only equities in 1931, less relevant to modern global funds)
#     max: 0.45   (best recorded calendar years for globally diversified equity)
#   80/20 stocks/bonds (e.g. broadly diversified with US, Canada, international):
#     average: 0.04 to 0.05
#     min: -0.33  (bonds cushion the crash — a bad equity year becomes less severe)
#     max: 0.38   (bonds also cap the upside in boom years)
#   60/40 stocks/bonds (balanced portfolio):
#     average: 0.03 to 0.04
#     min: -0.25
#     max: 0.35
#
# downturn_threshold: if the simulated return falls below this, the cash cushion is used
#   instead of selling investments at a loss. Set to 0 to disable.
# savings: the annual interest rate you earn on your cash cushion (e.g. HISA or GIC rate).
annual_growth_rate:
  average: 0.05
  min: -0.40
  max: 0.45
  downturn_threshold: -0.1
  savings: 0.005

# Choose the return sequence generator: mean, geometric_brownian_motion, constant
# If using `success_rate` mode, then choose either `mean` or `geometric_brownian_motion`
#
# `constant`: every year returns exactly the average. Easy to understand and produces
#   clean, predictable results, but completely unrealistic — markets don't do this.
#
# `mean`: returns are random each year but always average out to exactly your target
#   over the full simulation. Useful for understanding the model, but still unrealistic
#   because real retirement outcomes are sensitive to the *order* of good and bad years,
#   not just the average.
#
# `geometric_brownian_motion`: each year gets a realistic random return — mostly near
#   the average, with occasional good and bad years, including rare severe crashes.
#   This is the most realistic option and the recommended choice for success_rate mode.
#
#   Important caveat: this model will produce more conservative (lower) success rates
#   than you might expect from published research like the "4% rule". That's intentional —
#   the model is designed to stress-test your plan against scenarios that could be worse
#   than anything in the historical record. Real markets tend to recover after crashes
#   (mean reversion), but this model does not simulate that — every year is drawn
#   independently. Think of it as: "if the future is somewhat worse than history, will
#   my plan survive?" rather than: "how often has this worked historically?"
return_sequence_type: geometric_brownian_motion

# Optionally continue to make TFSA contributions during RRSP and Taxable drawdown phases.
# If you don't want to make any TFSA contributions during drawdown, set this to 0.
annual_tfsa_contribution: 0

# After-tax amount you need per year in retirement (NOT including TFSA contribution).
# Express this in today's dollars. This amount stays fixed — there is no built-in inflation
# adjustment. If you entered real (after-inflation) returns above, spending maintains its
# purchasing power. If you entered nominal returns, it will silently decline in real terms.
# To get an accurate number here, track your spending for at least a year, or review
# a year's worth of credit card statements and other sources of spending. Add up:
#   1. Variable spending (groceries, personal, entertainment, travel, etc.)
#   2. Fixed spending (any constant recurring payments)
#   3. Lumpy (e.g. new car, replace roof, replace appliances — divide total cost by
#      the number of years between each occurrence)
desired_spending: 40000

# Starting account balances.
# The cash_cushion will be used during market downturns (see downturn_threshold above).
# Set cash_cushion to 0 if you don't have one or don't want to model it.
accounts:
  rrsp: 600000
  taxable: 200000
  tfsa: 200000
  cash_cushion: 40000

# Enter the age at which you plan to start CPP and the monthly amount you're entitled to.
# You can find this value by logging in to your My Service Canada account.
#
# Note: the My Service Canada estimate assumes you continue working at your current income
# until the age you start CPP. If you're retiring earlier, your actual CPP will be lower
# due to additional years of no contributions.
# Use https://research-tools.pwlcapital.com/research/cpp to estimate what you may actually
# receive if retiring before you take CPP.
#
# To run the simulation without CPP, set monthly_amount to 0.
cpp:
  start_age: 65
  monthly_amount: 0

# Taxes
# Withholding tax may be greater than your actual tax bill — you'll get a refund when
# you file your return. In the first year of retirement, you'll need extra cash to float
# the difference. In subsequent years, the previous year's refund covers part of the gap.
#
# RRSP withholding tax rates:
# https://www.canada.ca/en/revenue-agency/services/tax/individuals/topics/rrsps-related-plans/making-withdrawals/tax-rates-on-withdrawals.html
#
# Assumption: you'll be withdrawing at least $15,000/year, which falls in the 30% bracket.
taxes:
  rrsp_withholding_rate: 0.3
```

---

## First Year Cash Flow

Before retiring, review the [First Year of RRSP Withdrawals](first_year.md) explainer. There is a nuance with RRSP withholding tax that can create a cash shortfall in your first year, and you need to account for it before pulling the trigger on retirement.

# Roadmap

## Enhancements

- Cash cushion to drawdown in case of severe market downturn
  - simpler: drawdown only, let user specify when market drops below x, use cash cushion if possible
  - complicated: refill when market high returns
  - configurable interest rate on savings (counts as taxable income but maybe ignore this for first attempt)
  - partial or not? Simplest would be you have exactly a year's worth and get one chance at dealing with downturn, and don't contribute to TFSA during this time.
  - interesting to compare success rate of this, vs dump the cash in taxable investment account
- Reverse tax calculator - too cumbersome to experiment with different spending/tfsa contribution amounts because need to experiment with external tax calculator each time to find required withdrawal to achieve desired after-tax income.
- Cascading/multi-account withdrawals - a little left in one account but not enough to fund that years spending so have to go to next account
- Inflation (simple: constant, complicated: varying).
- Tiered withholding tax: RRSP withdrawals could be less than 15K, in which case withholding tax is less: https://www.canada.ca/en/revenue-agency/services/tax/individuals/topics/rrsps-related-plans/making-withdrawals/tax-rates-on-withdrawals.html
- capital gains is really hard to project, for now assuming at 50% inclusion rate and re-investing dividends which constantly nudges up average cost, that half the gains will come out to < 15K, which is approx basic personal credit - i.e. no tax bill if this is your only source of income. But it could be higher.
- Start CPP at age 60, 65, or 70: https://research-tools.pwlcapital.com/research/cpp (complexity: amount shown on My Service Canada assumes you keep working until age 65, if retiring early, actual amount will be less, the PWL research tool attempts to account for that by having you enter all your earnings over the past years)
- OAS (make the value an input config as it could change)
- Assuming all accounts invested in the same thing, therefore growing at the same rate
- Transaction costs (RRSP withdrawal fee, TFSA withdrawal fee, ETF selling commission)
- During RRSP drawdown phase, taxable account is growing, and distributions are taxable (T3 issued)
- What if you reach age 71 and there's still funds in RRSP -> forced to RRIF and minimum withdrawals
- validation on loading AppConfig, consider bringing in ActiveModel for this, and easier to access attributes via `.` rather than `[...]`.
- make it easier to specify alternate input files
- Replay a particular sequence with alternate inputs

## Refactor

- test coverage
- CI
- `simulation_formatter` could be better named `simulation_printer`
- namespacing, eg: `simulation` for `simulation`, `simulation_evaluator`, and `simulation_formatter`

## Analysis

Document insights discovered from using this tool to analyze scenarios such as:

- How does classic FIRE fare
- Does draining down RRSP faster by also contributing to TFSA during this time help or hinder success rate
- How does use of cash cushion compare to having it invested in taxable account
- Given `geometric_brownian_motion` returns generator, what is the actual safe withdrawal rate

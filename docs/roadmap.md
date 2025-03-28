# Roadmap

## Enhancements

- Assuming all accounts invested in the same thing, therefore growing at the same rate
- Transaction costs (RRSP withdrawal fee, TFSA withdrawal fee, ETF selling commission)
- Support choice of multiple drawdown strategies (eg: TFSA first, taxable first)
- Other [enhancements](https://github.com/danielabar/retirement_drawdown_simulator_canada/issues?q=is%3Aissue%20state%3Aopen%20label%3Aenhancement)

### OAS

- OAS (make the value an input config as it could change)
- Clawback: https://www.canada.ca/en/services/benefits/publicpensions/old-age-security/benefit-amount.html

### Cash Cushion

- Subtlety: If severe market downturn and mandatory RRIF in effect, it draws entire amount from RRSP, even though would have preferred to use cash cushion. It would be more optimal in this case to calculate minimum rrif required, calculate after-tax amount left from that, then withdraw remainder from cash cushion - to minimize tax impact and having to sell more investments during downturn.
- Refill if needed when market return is high (would need to track what original balance was or have user specify how many years worth they want to keep in this bucket).

### Sequence of Returns

- Is [Geometric Brownian Motion](https://www.columbia.edu/~ks20/FE-Notes/4700-07-Notes-GBM.pdf) a reasonable way to simulate stock market returns? (i.e. goes up on average but with volatility and a number of "shocks" over time)
- If yes, is `ReturnSequences::GeometricBrownianMotionSequence` the correct implementation?
- If no, is there an alternative model/technique?

### Output

- Support multiple output/printer formats like console, csv, pdf, html, xlsx

### Ergonomics

- Validation on loading AppConfig, consider bringing in ActiveModel for this, and easier to access attributes via `.` rather than `[...]`.
- Make it easier to specify alternate input files
- Replay a particular sequence with alternate inputs

### Tax Complications

- Tiered withholding tax: RRSP withdrawals could be less than 15K, in which case withholding tax is less: https://www.canada.ca/en/revenue-agency/services/tax/individuals/topics/rrsps-related-plans/making-withdrawals/tax-rates-on-withdrawals.html
- Capital gains is really hard to project, for now assuming at 50% inclusion rate and re-investing dividends which constantly nudges up average cost, that half the gains will come out to < 15K, which is approx basic personal credit - i.e. no tax bill if this is your only source of income. But it could be higher.
- During RRSP drawdown phase, taxable account is growing, and distributions are taxable (T3 issued)
- When using a cash cushion, the interest rate (small as it is) will trigger some interest which counts as taxable income

## Refactor

- WIP rewrite tests loading AppConfig with hash rather than yaml - easier to maintain tests when don't have to have separate fixture file to understand input numbers
- Some duplication of code between reverse and forward tax calculators - modify reverse to use the forward when it needs to check a value
- CI

## Analysis

Document insights discovered from using this tool to analyze scenarios such as:

- How does classic FIRE fare (40K desired spending, save 25x === 1M)
  - 30 year retirement
  - 40 - 50 year retirement (success rate seems to drop significantly when going over 30 years!)
- Does draining down RRSP faster by also contributing to TFSA during this time help or hinder success rate?
- How does use of cash cushion compare to having it invested in taxable account?
- What is the actual safe withdrawal rate (seems to be a function of how many years spending in retirement)
- Compare to scenarios from https://youtu.be/HOZWpQuPzXc?si=ScDl5z_38fB79b9y

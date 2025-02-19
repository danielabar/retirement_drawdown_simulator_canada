# Roadmap

## Enhancements

- Maybe output should also have a column for how much was withdrawn
- When evaluating results, also capture what the final total balance was, and for success rate run, show average (or middle?) total balance
  - i.e. we're defining success by ending up with at least 1x (success_factor) desired spending, but maybe certain strategies result on average in MUCH MORE than this and we should show it somehow
- Output initial account balances and total balance
- Cash cushion refill if needed when market return is high (would need to track what original balance was or have user specify how many years worth they want to keep in this bucket)
- Cascading/multi-account withdrawals - a little left in one account but not enough to fund that years spending so have to go to next account
- Inflation (simple: constant, complicated: varying).
- Tiered withholding tax: RRSP withdrawals could be less than 15K, in which case withholding tax is less: https://www.canada.ca/en/revenue-agency/services/tax/individuals/topics/rrsps-related-plans/making-withdrawals/tax-rates-on-withdrawals.html
- capital gains is really hard to project, for now assuming at 50% inclusion rate and re-investing dividends which constantly nudges up average cost, that half the gains will come out to < 15K, which is approx basic personal credit - i.e. no tax bill if this is your only source of income. But it could be higher.
- OAS (make the value an input config as it could change)
- Assuming all accounts invested in the same thing, therefore growing at the same rate
- Transaction costs (RRSP withdrawal fee, TFSA withdrawal fee, ETF selling commission)
- During RRSP drawdown phase, taxable account is growing, and distributions are taxable (T3 issued)
- What if you reach age 71 and there's still funds in RRSP -> forced to RRIF and minimum withdrawals
- instead of space separated console "table" output, consider gem, should make it easier to add columns and right-align numbers https://github.com/piotrmurach/tty-table
- visual/chart https://github.com/red-data-tools/unicode_plot.rb and https://red-data-tools.github.io/unicode_plot.rb/0.0.5/ of returns, and total_balance over time
- support choice of multiple drawdown strategies (eg: TFSA first, taxable first)
- validation on loading AppConfig, consider bringing in ActiveModel for this, and easier to access attributes via `.` rather than `[...]`.
- make it easier to specify alternate input files
- support choice of output types, currently its only ConsolePrinter
- Replay a particular sequence with alternate inputs

## Refactor

- WIP rewrite tests loading AppConfig with hash rather than yaml - easier to maintain tests when don't have to have separate fixture file to understand input numbers
- Some duplication of code between reverse and forward tax calculators - modify reverse to use the forward when it needs to check a value
- CI
- `simulation_formatter` could be better named `simulation_printer` (worry about this later if adding more printer options like console, pdf, html, etc)

## Analysis

Document insights discovered from using this tool to analyze scenarios such as:

- How does classic FIRE fare (40K desired spending, save 25x === 1M)
  - 30 year retirement
  - 40 - 50 year retirement (success rate seems to drop significantly when going over 30 years!)
- Does draining down RRSP faster by also contributing to TFSA during this time help or hinder success rate?
- How does use of cash cushion compare to having it invested in taxable account (no difference!)
- Given `geometric_brownian_motion` returns generator, what is the actual safe withdrawal rate (seems to be a function of how many years spending in retirement)
  - Initial analysis shows the only way to get a success rate at or over 95% for a long retirement is to count on CPP
- How does starting CPP at age 60 vs 65 vs 70 impact success rate?

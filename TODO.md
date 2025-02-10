# TODO

- RRSP withdrawals could be less than 15K, in which case withholding tax is less: https://www.canada.ca/en/revenue-agency/services/tax/individuals/topics/rrsps-related-plans/making-withdrawals/tax-rates-on-withdrawals.html
- inflation
- Assuming all accounts invested in the same thing, therefore growing at the same rate
- RRSP withdrawal fee?
- TFSA withdrawal fee?
- ETF selling commission?
- capital gains is really hard to project, for now assuming at 50% inclusion rate and re-investing dividends which constantly nudges up average cost, that half the gains will come out to < 15K, which is approx basic personal credit - i.e. no tax bill if this is your only source of income. But it could be higher.
- Start CPP at age 60, 65, or 70: https://research-tools.pwlcapital.com/research/cpp (complexity: amount shown on My Service Canada assumes you keep working until age 65, if retiring early, actual amount will be less, the PWL research tool attempts to account for that by having you enter all your earnings over the past years)
- OAS (make the value an input config as it could change)
- During RRSP drawdown phase, taxable account is growing, and distributions are taxable (T3 issued)
- What if you reach age 71 and there's still funds in RRSP -> forced to RRIF and minimum withdrawals
- Ignoring complexity of multi-account withdrawals - a little left in one account but not enough to fund that years spending so have to go to next account - implement cascade?
- COMPLICATED: Cash cushion to drawdown in case of severe market downturn, but how to replenish? When market goes back up beyond average sell more to refill?
- validation on loading AppConfig, consider bringing in ActiveModel for this, and easier to access attributes via `.` rather than `[...]`.

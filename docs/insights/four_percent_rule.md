# Is the 4% Rule Actually Safe?

## Contents

- [Is the 4% Rule Actually Safe?](#is-the-4-rule-actually-safe)
  - [Contents](#contents)
  - [Where the "95% Safe" Figure Comes From](#where-the-95-safe-figure-comes-from)
  - [What This Simulator Shows](#what-this-simulator-shows)
    - [The Baseline Scenario](#the-baseline-scenario)
    - [The Canadian Retiree: Adding CPP and OAS](#the-canadian-retiree-adding-cpp-and-oas)
  - [Longer Retirements: What FIRE Changes](#longer-retirements-what-fire-changes)
    - [FIRE at 3% with Modest CPP: What Does It Take?](#fire-at-3-with-modest-cpp-what-does-it-take)
    - [The Survivorship Problem](#the-survivorship-problem)
  - [Key Takeaways](#key-takeaways)

The 4% rule is probably the most cited piece of advice in personal finance: save 25 times your annual spending, withdraw 4% per year, and your money should last 30 years. It's often described as having a "95% success rate," implying only 1 in 20 retirees would run out of money. But where does that number actually come from, and does it hold up under scrutiny?

## Where the "95% Safe" Figure Comes From

The 4% rule originates from research by William Bengen (1994) and was refined by the Trinity Study (1998). Both studies analyzed historical US stock and bond returns going back to 1926. Bengen's question was: what is the highest annual withdrawal rate a retiree could have used and still not run out of money across any 30-year historical period? His answer: 4% (technically 4.15%) — the rate that survived even the worst historical starting years. The Trinity Study then tested a range of rates (3%–12%) across all rolling 30-year periods and reported success rates for each. At 4%, the historical success rate across all periods was roughly 95%.

There are several reasons why this figure may not apply to you:

**1. It's based on US historical data.** The US stock market over the 20th century was exceptionally strong — arguably the best-performing major market in history. Research using global historical data tends to produce lower safe withdrawal rates (around 2.5–3.5% depending on the country and methodology).

**2. It's backward-looking.** The studies replay actual historical sequences. The future may contain stretches worse than anything in the historical record — no country has been immune to long periods of stagnant or negative real returns.

**3. It's for a 30-year retirement.** If you're retiring at 65 and have a 30-year horizon (to age 95), the 4% rule's 30-year window applies. But if you're retiring younger — say at 55 or 50 — a 40 or 45-year retirement is a very different problem.

## What This Simulator Shows

This simulator uses Geometric Brownian Motion to generate return sequences, which produces more conservative results than historical replay — by design. The model doesn't incorporate mean reversion (markets recovering after crashes), so it can generate extended bad stretches that historical markets recovered from faster. Think of it as answering: *"If the future is somewhat worse than history, will my plan survive?"*

### The Baseline Scenario

The setup: $1,000,000 portfolio (RRSP $600K, Taxable $200K, TFSA $200K), $40,000/year spending, retiring at 65, running to age 95, no CPP, modelled with 60/40 stock/bond real returns across 1,000 simulations.

```bash
ruby main.rb success_rate demo/four_percent_rule.yml
```

| | |
|---|---|
| **Withdrawal Rate** | 4.0% |
| **Success Rate** | 69.4% |

| Percentile | Final Balance |
|---|---|
| 5th | $8,218 |
| 10th | $15,297 |
| 25th | $36,212 |
| 50th (Median) | $451,600 |
| 75th | $1,272,092 |
| 90th | $2,425,914 |
| 95th | $3,221,758 |

**Success rate: 69.4%**, compared to the commonly cited 95% from historical US data. That gap is significant — it means roughly 1 in 3 simulated retirees runs out of money before 95, not 1 in 20.

The distribution is highly skewed. The median survivor ends with ~$452K — about 45% of their starting portfolio, still in reasonable shape. But the 25th percentile ends with only $36K, and below that portfolios are effectively empty. Meanwhile, the luckiest scenarios (top quartile) see the portfolio grow substantially, ending with over $1M.

> [!NOTE]
> The original 4% rule research considers reaching the end of the simulation period with even $1 remaining a "success." Most people would feel quite differently about reaching their late 80s with a rapidly dwindling portfolio, even if it technically lasts until the end. The `success_factor` setting lets you define a more meaningful success threshold — for example, finishing with at least 1x or 1.5x your annual spending still in the portfolio.

### The Canadian Retiree: Adding CPP and OAS

The original 4% rule was designed without any government income — pure portfolio withdrawals only. A typical Canadian retiring at 65 would also receive CPP and OAS, both of which reduce the amount the portfolio needs to cover each year. This scenario uses the same setup as the baseline but adds a typical CPP benefit of $800/month (roughly the average for someone taking CPP at 65) and full OAS of ~$742/month — both starting at 65.

```bash
ruby main.rb success_rate demo/canadian_retiree.yml
```

| | |
|---|---|
| **Withdrawal Rate** | 4.0% |
| **Success Rate** | 98.7% |

| Percentile | Final Balance |
|---|---|
| 5th | $221,137 |
| 10th | $366,949 |
| 25th | $759,405 |
| 50th (Median) | $1,375,839 |
| 75th | $2,391,878 |
| 90th | $3,720,114 |
| 95th | $4,654,795 |

Adding $800/month CPP and ~$742/month OAS lifts the success rate from 69.4% to 98.7% — a transformation, not just an improvement. Combined guaranteed income of ~$18,500/year covers about 46% of the $40,000 spending need, leaving the portfolio to fund only the remainder. At that level of coverage, poor market sequences rarely become fatal.

The effect on the lower tail is dramatic. The 5th percentile balance jumps from $8K to $221K — scenarios that would have barely survived in the pure-portfolio case now end with more than five years of spending intact. The 25th percentile goes from $36K to $759K, and the median ends at $1.38M vs $452K in the baseline. This is the power of guaranteed income that doesn't depend on markets: CPP and OAS keep arriving regardless of what the portfolio is doing, directly neutralizing sequence-of-returns risk. A bad decade early in retirement drains the portfolio far less when nearly half of spending is covered by income the portfolio doesn't need to generate.

## Longer Retirements: What FIRE Changes

FIRE — Financial Independence, Retire Early — is a movement built around aggressive saving and investing with the goal of retiring decades before the traditional age. Many adherents assume the 4% rule applies equally well to retirements of 40 or even 50 years, retiring at 45 or younger — but the evidence suggests otherwise.

The 4% rule was designed for a 30-year retirement. If you're planning to retire significantly earlier than 65, your simulation horizon is longer — and longer horizons are harder on withdrawal strategies. The same $1,000,000 / $40,000 setup, but retiring at 45 — a 50-year horizon — produces meaningfully lower success rates than the 30-year result above. FIRE adherents also tend to hold more aggressive, equity-heavy portfolios: with a 50-year runway, there's time to ride out crashes, and bonds drag down long-term growth. So this scenario uses 100% global equity returns rather than the 60/40 mix above.

```bash
ruby main.rb success_rate demo/fire.yml
```

| | |
|---|---|
| **Withdrawal Rate** | 4.0% |
| **Success Rate** | 47.4% |

| Percentile | Final Balance |
|---|---|
| 5th | $5,250 |
| 10th | $9,553 |
| 25th | $21,020 |
| 50th (Median) | $38,753 |
| 75th | $3,385,920 |
| 90th | $10,365,396 |
| 95th | $18,535,817 |

**Success rate: 47.4%** — worse than a coin flip, down from 69.4% for the 30-year scenario.

The percentile distribution here is striking. The median final balance is only $39K, meaning more than half of all simulated retirees end up essentially empty. Yet the 75th percentile is $3.4M, the 90th is $10.4M, and the 95th is $18.5M. This is a much more extreme version of the skew seen in the 30-year scenario: with 50 years of 100% equity growth, the scenarios that survive tend to compound into very large numbers, while the failures are total.

There are two compounding reasons for the lower success rate:

1. **More years of withdrawals.** More time means more opportunities for a bad sequence to derail the plan. A bad decade early in retirement — before the portfolio has had time to grow — can be unrecoverable over a 50-year horizon.

2. **No CPP.** Retiring at 45 means 20+ years before CPP begins, during which you're relying entirely on your portfolio. The CPP insights doc ([when to take CPP](when_to_take_cpp.md)) explores how much CPP start age affects outcomes — the longer the gap before it starts, the more exposed the portfolio is.

### FIRE at 3% with Modest CPP: What Does It Take?

Three adjustments FIRE researchers commonly suggest for long retirements: use a lower withdrawal rate, work a little longer, and count on some modest government income. Applied together — retiring at 50 instead of 45, dropping to a 3% withdrawal rate, and factoring in ~$650/month CPP and full OAS (~$742/month) both arriving at 65 — the picture changes meaningfully.

```bash
ruby main.rb success_rate demo/fire_3pct_modest_cpp_age50.yml
```

| | |
|---|---|
| **Withdrawal Rate** | 3.0% |
| **Success Rate** | 83.9% |

| Percentile | Final Balance |
|---|---|
| 5th | $7,709 |
| 10th | $15,008 |
| 25th | $506,155 |
| 50th (Median) | $2,276,049 |
| 75th | $6,543,435 |
| 90th | $16,550,582 |
| 95th | $24,542,783 |

From 47.4% with the pure 4% FIRE scenario to 83.9% here — a substantial improvement from pulling all three levers plus OAS. The lower tail shifts dramatically: the 25th percentile goes from $21K to $506K, meaning the scenarios that would have failed most badly are the ones that benefit most from the shorter horizon and CPP+OAS arriving 15 years in rather than 20.

The bimodal character remains — the 5th and 10th percentiles are still essentially empty, while above the median the numbers are enormous. A fourth lever not captured here is spending flexibility: reducing withdrawals in bad years and spending more in good ones is probably the most practical tool available, since it doesn't require more capital or more working years.

### The Survivorship Problem

If you've read FIRE blogs and come away thinking the 4% rule at $1M is basically guaranteed, there's a good reason for that — but it has more to do with timing than with math.

Many of the most prominent FIRE success stories involve people who started investing seriously around 2008–2012. Yes, there was a crash. But the S&P 500 then went on one of the longest bull runs in history, and a straightforward all-equity strategy — popularized by JL Collins' "VTSAX and chill" approach — turned that tailwind into $1M portfolios in roughly a decade. Those people pulled the trigger. Since then, even accounting for the COVID dip, US markets have continued upward. Of course they're doing fine.

The analysis here doesn't say FIRE doesn't work — look at the upper percentiles in the pure FIRE scenario and you'll see outcomes that would make any blogger's early retirement look comfortable. What it says is that those outcomes sit alongside a wide range of much worse ones. Someone who retired in their mid-thirties with $1M in 2012 got lucky with sequence of returns in a way that isn't guaranteed to repeat.

There's also an obvious survivorship bias at work. The FIRE movement became culturally visible during this specific bull market era, so nearly every public story is a story from that window. And whose going to write the blog that says: *I tried FIRE, ran out of money at 58, had to re-enter the job market after a decade-long resume gap, in a market of mass layoffs and age discrimination, competing against people half my age.*

## Key Takeaways

1. **The "95% safe" number comes from US historical data and a 30-year window.** It may not apply to your situation.
2. **This simulator tends to produce lower success rates than historical studies** — deliberately, because it can generate scenarios worse than history, including those with no mean reversion after crashes.
3. **For a 30-year Canadian retirement, 4% looks closer to 69% safe** under this model — still not catastrophic, but meaningfully different from the widely cited figure.
4. **For longer retirements (FIRE), success rates drop further.** A lower withdrawal rate, a few extra working years, and modest CPP+OAS each move the needle — pulling all levers together gets from 47.4% to 83.9%.
5. **The percentile distribution matters as much as the success rate.** A plan with 70% success and a $400K median final balance is very different from one with 70% success and a $0 median final balance. Look at both.

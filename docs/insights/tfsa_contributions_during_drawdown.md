# TFSA Contributions During Drawdown: Does It Help?

## Contents

- [Why It's Not Obvious](#why-its-not-obvious)
- [The Setup](#the-setup)
- [$40,000/year Spending](#40000year-spending)
  - [Without TFSA Contribution](#without-tfsa-contribution)
  - [With $7,000/year TFSA Contribution](#with-7000year-tfsa-contribution)
- [$35,000/year Spending (Lower Tax Bracket)](#35000year-spending-lower-tax-bracket)
  - [Without TFSA Contribution](#without-tfsa-contribution-1)
  - [With $7,000/year TFSA Contribution](#with-7000year-tfsa-contribution-1)
- [Early Retirement (FIRE): Does the Longer Horizon Change Things?](#early-retirement-fire-does-the-longer-horizon-change-things)
  - [Without TFSA Contribution](#without-tfsa-contribution-2)
  - [With $7,000/year TFSA Contribution](#with-7000year-tfsa-contribution-2)
- [What We Found](#what-we-found)
- [Key Takeaways](#key-takeaways)

## Why It's Not Obvious

During RRSP drawdown, this simulator lets you configure an optional annual TFSA contribution. The idea is appealing: pull money out of the RRSP now (paying tax at a relatively low rate), park some of it in the TFSA, and enjoy tax-free growth and withdrawals later. It also drains the RRSP faster, which can reduce or eliminate forced RRIF excess withdrawals at age 71.

But the cost is immediate. Making a TFSA contribution on top of your spending means withdrawing more from the RRSP each year — and RRSP withdrawals are taxable income. You're paying tax today to move money from one tax shelter to another, in exchange for a future benefit that may be years away.

Whether that tradeoff improves your long-term success rate — not just your tax efficiency — is the question. A strategy that's good for minimizing taxes paid isn't necessarily good for your retirement survival odds. We're focused on the latter.

One variable that matters: your tax bracket. If your spending is low enough that even with the TFSA contribution you stay in a relatively low bracket, the upfront tax cost is smaller and the tradeoff might look different than for someone whose total withdrawal pushes into a higher bracket.

To make that concrete for the scenarios below: in Ontario, the combined federal + provincial marginal rate sits at roughly 20.1% up to about $52,000 of gross income, then jumps to about 24.1%. CPP is taxable income, so the $9,600/year from the $800/month CPP assumption counts toward that threshold. At $40,000 spending *without* a TFSA contribution, total gross income needed is about $46,200 — inside the 20.1% bracket. Add the $7,000 TFSA contribution on top, and the total rises to about $55,100, which crosses into the 24.1% bracket. At $35,000 spending, neither scenario crosses: roughly $39,900 without the contribution and $48,700 with it — both stay at 20.1%. The two spending levels run at meaningfully different tax costs per dollar contributed to the TFSA.

## The Setup

All scenarios use a Canadian retiree profile: retiring at 65, running to 95 (30-year horizon), CPP of $800/month (roughly the average for someone taking CPP at 65), and a 60/40 stock/bond portfolio. The withdrawal rate is set at 3.5% — slightly more conservative than the classic 4% rule — by sizing the portfolio accordingly. The TFSA contribution amount is $7,000/year, the 2024–2025 annual limit.

## $40,000/year Spending

Investable portfolio (RRSP + Taxable + TFSA) sized to a 3.5% withdrawal rate: $40,000 ÷ 0.035 = **$1,143,000**, plus a $40,000 cash cushion on top. With the TFSA contribution, the portfolio must effectively fund $47,000/year equivalent — the extra $7,000 gross RRSP withdrawal needed to cover the contribution after tax.

### Without TFSA Contribution

```bash
ruby main.rb success_rate demo/tfsa_drawdown_40k.yml
```

| | |
|---|---|
| **Withdrawal Rate** | 3.5% |
| **Success Rate** | 94.6% |

| Percentile | Final Balance |
|---|---|
| 5th | $41,923 |
| 10th | $231,670 |
| 25th | $620,906 |
| 50th (Median) | $1,215,376 |
| 75th | $2,332,383 |
| 90th | $3,857,561 |
| 95th | $5,262,451 |

A 94.6% success rate is a comfortable starting point — the combination of a conservative 3.5% withdrawal rate and CPP income leaves the portfolio under much less pressure than the 4% rule scenarios. The distribution is also notably well-behaved: the 5th percentile still has $41K remaining, and the median ends at $1.2M. Even bad sequences of returns don't wipe people out here — they just leave less.

### With $7,000/year TFSA Contribution

Everything identical to the scenario above, except `annual_tfsa_contribution: 7000` is added on top of the $40,000 spending. The portfolio must now fund both.

```bash
ruby main.rb success_rate demo/tfsa_drawdown_40k_contrib.yml
```

| | |
|---|---|
| **Withdrawal Rate** | 3.5% |
| **Success Rate** | 94.4% |

| Percentile | Final Balance |
|---|---|
| 5th | $37,346 |
| 10th | $181,101 |
| 25th | $553,963 |
| 50th (Median) | $1,181,389 |
| 75th | $2,367,017 |
| 90th | $3,863,125 |
| 95th | $5,171,437 |

The success rate moves from 94.6% to 94.4% — a difference that's within simulation noise and means nothing in practice. Every percentile is slightly lower with the contribution, which makes sense: the portfolio is being drawn on more each year to fund the TFSA, and the future tax-free benefit doesn't compensate enough within a 30-year window to show up in the survival odds. At this spending level, the TFSA contribution strategy doesn't improve your retirement security — it just moves money between accounts.

## $35,000/year Spending (Lower Tax Bracket)

Investable portfolio (RRSP + Taxable + TFSA) sized to a 3.5% withdrawal rate: $35,000 ÷ 0.035 = **$1,000,000** exactly, plus a $35,000 cash cushion on top. With the TFSA contribution, total annual draw is the equivalent of $42,000. As described above, both the baseline and contribution scenarios stay within the 20.1% marginal bracket — unlike the $40K case, where adding the TFSA contribution crosses into 24.1%. If the bracket difference is going to show up anywhere, it should show up here.

### Without TFSA Contribution

```bash
ruby main.rb success_rate demo/tfsa_drawdown_35k.yml
```

| | |
|---|---|
| **Withdrawal Rate** | 3.5% |
| **Success Rate** | 96.0% |

| Percentile | Final Balance |
|---|---|
| 5th | $65,276 |
| 10th | $227,181 |
| 25th | $590,156 |
| 50th (Median) | $1,286,984 |
| 75th | $2,179,829 |
| 90th | $3,429,089 |
| 95th | $4,529,104 |

A 96.0% success rate — slightly better than the $40K scenario's 94.6%, which makes sense. Spending $5,000 less per year means CPP covers a larger fraction of the need, the portfolio is drawn on less aggressively, and a smaller portfolio (sized to $35K spending) is required in the first place. The lower tail is also more comfortable: the 5th percentile has $65K remaining versus $42K in the $40K case.

### With $7,000/year TFSA Contribution

Everything identical to the scenario above, except `annual_tfsa_contribution: 7000` is added on top of the $35,000 spending.

```bash
ruby main.rb success_rate demo/tfsa_drawdown_35k_contrib.yml
```

| | |
|---|---|
| **Withdrawal Rate** | 3.5% |
| **Success Rate** | 95.6% |

| Percentile | Final Balance |
|---|---|
| 5th | $60,024 |
| 10th | $188,944 |
| 25th | $560,590 |
| 50th (Median) | $1,187,282 |
| 75th | $2,111,475 |
| 90th | $3,317,603 |
| 95th | $4,484,542 |

The success rate falls from 96.0% to 95.6% — the same marginal pattern as the $40K case (94.6% → 94.4%). Staying in the same marginal bracket didn't change the result. The TFSA contribution still costs more each year than the future tax-free benefit returns within the simulation window, regardless of whether you crossed a bracket or not. The small drop in every percentile tells the same story as before: the portfolio is being drawn on more each year, and the model doesn't recover that cost through future tax savings within 30 years.

## Early Retirement (FIRE): Does the Longer Horizon Change Things?

The two scenarios above use a 30-year retirement horizon (age 65 to 95). What about retiring at 45 with a 50-year horizon? The extra decades of tax-free compounding could change the calculus significantly — and the question of whether the benefit eventually outstrips the upfront tax cost becomes much more plausible when there are 50 years for it to play out.

Same $40,000 spending and $1,143,000 investable portfolio as the first section (3.5% withdrawal rate), but retiring at 45 with 100% equity returns and modest CPP of $500/month at 65 — roughly what 20 years of median-income work earns. The portfolio carries the full $40K/year load for 20 years before CPP arrives.

### Without TFSA Contribution

```bash
ruby main.rb success_rate demo/tfsa_drawdown_fire.yml
```

| | |
|---|---|
| **Withdrawal Rate** | 3.5% |
| **Success Rate** | 59.6% |

| Percentile | Final Balance |
|---|---|
| 5th | $4,305 |
| 10th | $8,848 |
| 25th | $21,635 |
| 50th (Median) | $764,556 |
| 75th | $4,815,576 |
| 90th | $14,199,368 |
| 95th | $22,950,739 |

A 59.6% success rate — much lower than either standard retirement scenario, which is expected. A 50-year horizon with no income support for the first 20 years is a much harder problem than a 30-year horizon with CPP from day one. The distribution has the extreme bimodality typical of long FIRE simulations: the 25th percentile is essentially empty ($22K) while the 75th is $4.8M. With 50 years of 100% equity returns, the scenarios that survive tend to compound into very large numbers; the ones that fail tend to fail decisively.

### With $7,000/year TFSA Contribution

Everything identical, with `annual_tfsa_contribution: 7000` added on top of $40,000 spending.

```bash
ruby main.rb success_rate demo/tfsa_drawdown_fire_contrib.yml
```

| | |
|---|---|
| **Withdrawal Rate** | 3.5% |
| **Success Rate** | 61.8% |

| Percentile | Final Balance |
|---|---|
| 5th | $5,701 |
| 10th | $10,534 |
| 25th | $24,713 |
| 50th (Median) | $823,620 |
| 75th | $5,209,428 |
| 90th | $13,747,721 |
| 95th | $25,681,998 |

The direction flips. The success rate rises from 59.6% to 61.8% — a +2.2 percentage point improvement, compared to the slight *declines* seen in both 30-year scenarios. Every percentile improves, with the median up from $765K to $824K. The TFSA contribution actually helps here.

Two things work together to produce this reversal. First, the tax cost is lower: with no CPP income in the first 20 years, the gross RRSP withdrawal needed to fund $40K spending is lower than in the standard retirement case, which means the TFSA contribution adds less additional taxable income. Second — and more importantly — money moved into the TFSA at age 45 has up to 50 years to compound tax-free before the simulation ends. The crossover point where future tax savings outweigh today's upfront cost actually lands within the window this time.

The improvement is real but modest. The 5th percentile goes from $4K to $6K — both are effectively zero, and the strategy doesn't rescue the people who were going to fail anyway. What it does is shift the already-surviving scenarios to slightly better outcomes across the board.

## What We Found

In standard retirement (30-year horizon, CPP from day one), adding a $7,000/year TFSA contribution produces essentially the same result regardless of spending level or whether it crosses a marginal tax bracket: the success rate is flat to marginally lower, and every percentile shifts slightly downward. The bracket crossing at $40K spending (20.1% → 24.1%) didn't make it meaningfully worse than the $35K scenario that stayed within the bracket. The tax cost isn't the deciding factor.

The deciding factor is the time horizon. In the early retirement scenario — 50 years, no CPP for 20 years — the direction reverses. The strategy adds +2.2 percentage points to the success rate and improves every percentile. Fifty years is long enough for the tax-free compounding benefit to outweigh the upfront cost within the simulation window. Thirty years isn't.

The underlying tradeoff is the same in every case: more RRSP withdrawn today, more tax paid today, less in the portfolio compounding now — in exchange for tax-free growth and withdrawals later. The question is whether "later" arrives within your planning horizon. For a 65-year-old, the payoff is far enough out that it doesn't move survival odds. For a 45-year-old, it's close enough to matter.

## Key Takeaways

1. **In standard retirement (30-year horizon), TFSA contributions during drawdown don't improve survival odds.** At both spending levels tested, the success rate was flat to marginally lower — not higher. Bracket differences between scenarios didn't change the pattern.
2. **In early retirement (50-year horizon), the strategy helps.** The success rate rose +2.2 percentage points, and every percentile improved. The longer horizon is what makes the difference — not the spending level or the tax bracket.
3. **The cost is immediate; the benefit is future.** The tradeoff is the same in every case. What changes is whether your planning horizon is long enough for the future benefit to arrive. Thirty years isn't. Fifty years is.
4. **This doesn't mean avoiding the strategy in standard retirement.** There are legitimate reasons to shift money from RRSP to TFSA during drawdown: reducing RRIF forced withdrawals at 71, minimizing OAS clawback, estate planning, or tax diversification (none of which this simulator models). Those benefits are real — they just don't show up in a success rate metric. If one of those goals matters to you, the marginal survival cost is small enough that it needn't be a barrier.

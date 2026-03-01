# When to Take CPP?

Canadians can start collecting CPP at age 60, but can earn more by delaying to age 70 (earning a certain percentage more for every year of delay). Assuming a healthy life expectancy and enough savings to start, the general advice is to delay taking CPP. But many people have an intuition that it's better to just "take the money" as soon as possible.

Another way to frame the question of when to take CPP is how does delaying impact the success rate of your retirement plan? This program allows you to define success rate by reaching the max age with 1x, 2x etc. in desired spending left.

Let's consider a 60 year old that wants to retire with an annual desired spending of `$40,000`. They have a 1M portfolio divided among RRSP, taxable, and TFSA. They define success as reaching age 95 with at least their desired spending left.

Let's assume they've been working for 40 years, earning the maximum pensionable earnings each year. Depending on when they start CPP, they would receive the following **fixed** monthly amounts for life:

| Age | Amount |
| --- | ------ |
| 60  | 896    |
| 65  | 1524   |
| 70  | 2223   |

Once CPP starts, the amount remains the same (except for inflation adjustments), so the decision of when to begin has long-term consequences.

> [!TIP]
>  See https://research-tools.pwlcapital.com/research/cpp for CPP calculator that considers years worked and earnings.

In all three scenarios below, this person retires at 60. The retirement age is constant — only the CPP start age changes. This is what makes it a fair comparison: the same portfolio, the same spending, the same 35-year horizon, just different CPP timing decisions.

We can run the simulation in "success rate" mode, which runs it over and over, calculating what percentage of runs result in success. Then we can modify the age at which CPP is taken to see how this affects the success rate.

## CPP at 60

Taking CPP at 60 means smaller monthly payments — $896/month — but they start arriving immediately, reducing the portfolio’s workload from year one of retirement.

```bash
ruby main.rb success_rate demo/cpp_at_60.yml
```

| | |
|---|---|
| **Withdrawal Rate** | 4.0% |
| **Success Rate** | 94.9% |

| Percentile | Final Balance |
|---|---|
| 5th | $41,338 |
| 10th | $292,795 |
| 25th | $777,347 |
| 50th (Median) | $1,641,191 |
| 75th | $3,093,438 |
| 90th | $5,586,025 |
| 95th | $7,039,281 |

A 94.9% success rate means roughly 1 in 20 retirees in this scenario runs out of money before 95. The 5th percentile balance of $41K confirms how close those scenarios are — retirement ends with essentially nothing. The 10th percentile at $293K means 1 in 10 retirees ends with under three years of spending left.

The upper half is much more comfortable: the median final balance is $1.6M, and the top quartile ends well above the starting portfolio. The wide spread from near-zero to $7M reflects how much sequence-of-returns risk dominates a 35-year retirement. The $40,000 cash cushion provides one year of spending as a buffer against bad markets, but it’s a one-time tool — once depleted in a downturn, it’s permanently gone with no refill mechanism. CPP’s $896/month provides some ongoing relief, but partial coverage for 35 years leaves significant exposure in the lower tail.

## CPP at 65

Delaying CPP to 65 means no government income for the first five years — the portfolio carries the full $40,000/year load alone. In exchange, the monthly payment rises from $896 to $1,524.

```bash
ruby main.rb success_rate demo/cpp_at_65.yml
```

| | |
|---|---|
| **Withdrawal Rate** | 4.0% |
| **Success Rate** | 97.2% |

| Percentile | Final Balance |
|---|---|
| 5th | $208,834 |
| 10th | $459,940 |
| 25th | $987,748 |
| 50th (Median) | $1,931,847 |
| 75th | $3,369,207 |
| 90th | $5,703,553 |
| 95th | $7,399,626 |

The success rate rises from 94.9% to 97.2% (+2.3 percentage points), but the more striking change is in the lower tail. The 5th percentile jumps from $41K to $209K — a fivefold increase. The 10th percentile goes from $293K to $460K. These aren’t just numbers getting better; they represent a qualitative shift from near-failure to a meaningful financial cushion.

The reason is sequence-of-returns risk. The critical period for any retirement portfolio is the first decade: bad returns early, combined with forced withdrawals, compound into irreversible damage. CPP at 65 starts reducing portfolio withdrawals right at the midpoint of that 10-year vulnerable window. From age 65 onwards, the portfolio no longer carries the full spending load alone. That ongoing relief is enough to convert many of the near-failure scenarios into survivors, which is why the lower tail improves so dramatically.

## CPP at 70

Delaying all the way to 70 means a full decade with no CPP — the heaviest ask on the portfolio of the three scenarios. The payoff is the maximum monthly amount: $2,223.

```bash
ruby main.rb success_rate demo/cpp_at_70.yml
```

| | |
|---|---|
| **Withdrawal Rate** | 4.0% |
| **Success Rate** | 98.8% |

| Percentile | Final Balance |
|---|---|
| 5th | $304,434 |
| 10th | $569,436 |
| 25th | $1,070,762 |
| 50th (Median) | $1,961,542 |
| 75th | $3,680,474 |
| 90th | $5,825,029 |
| 95th | $8,209,128 |

Delaying CPP to 70 pushes the success rate to 98.8% — the highest of the three scenarios. But the improvement over CPP at 65 (+1.6 percentage points) is smaller than the improvement from 60 to 65 (+2.3 percentage points). The intuition that a 46% higher monthly payment should buy proportionally more safety doesn’t quite hold, and the reason is structural.

Delaying to 70 means the portfolio faces the full $40,000/year drawdown burden for the entire first decade of retirement — the highest-risk window for any retirement plan. The cash cushion covers roughly one year of exposure when a severe downturn hits, but once depleted it’s permanently gone. By the time CPP starts paying $2,223/month at age 70, the worst-case scenarios have already played out: a bad sequence of returns in the first decade has depleted the portfolio past the point of recovery, and higher income from 70 onwards can’t undo that damage.

CPP at 65 breaks the 10-year vulnerable window in half. The portfolio still faces 5 unprotected years (ages 60–64), but from 65 onwards the spending load drops meaningfully. The marginal scenarios — those that barely survived — had enough portfolio left at 65 for CPP to rescue them. The scenarios that fail even with CPP at 65 are the severe ones: two or three catastrophically bad years in the first decade that wrecked the portfolio before CPP could help. Those same scenarios fail with CPP at 70 too, because the damage was done before age 70 arrived.

The lower tail improvement is real and worth noting. The 5th percentile rises from $209K to $304K, and the 10th from $460K to $569K — these are scenarios that survive either way but end with meaningfully more in reserve. The average final balance rises to $2.82M (vs. $2.61M at 65), and the upper percentiles are higher across the board. In scenarios with good or median returns, the larger CPP payment compounds into substantially more wealth by 95.

## The Bottom Line

| CPP Start Age | Monthly CPP | Success Rate |
|---|---|---|
| 60 | $896 | 94.9% |
| 65 | $1,524 | 97.2% |
| 70 | $2,223 | 98.8% |

Delaying CPP improves retirement success rates across the board, but the improvement is concentrated where it matters most: the lower tail. The largest single gain is the jump from 60 to 65, because CPP at 65 starts reducing portfolio withdrawals during the second half of the highest-risk decade. CPP at 70 adds further improvement, but with a smaller success rate gain — the borderline cases are already rescued at 65, and what remains failing at 97.2% are severe early-downturn scenarios that higher income from 70 can’t undo.

For those in good health with sufficient savings to bridge the gap: delaying is the right call. The question of how far — 65 or 70 — is a closer one than it might appear. The gap in success rate is only 1.6 percentage points.

> [!NOTE]
> The absolute success rates here are lower than historical replay studies would show — by design. See [how it works](../how-it-works.md#geometric_brownian_motion-recommended) for a full explanation of how this simulator's GBM model acts as a stress test rather than a historical backtest. The case for 70 is strongest if you’re focused on the lower tail (where the improvement is clearest) and if you have enough portfolio to sustain a decade of full drawdown without taking on excessive sequence-of-returns risk in the process.

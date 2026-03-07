# When to Take CPP?

Canadians can start collecting CPP at age 60, but can earn more by delaying to age 70 (earning a certain percentage more for every year of delay). Assuming a healthy life expectancy and enough savings to start, the general advice is to delay taking CPP. But many people have an intuition that it's better to just "take the money" as soon as possible.

Another way to frame the question of when to take CPP is how does delaying impact the success rate of your retirement plan? This program allows you to define success rate by reaching the max age with 1x, 2x etc. in desired spending left.

Let's consider a 60 year old retiring in a high-cost-of-living city like Vancouver or Toronto with an annual desired spending of `$60,000` — a modest but realistic budget for a single person renting in these cities. They have a `$1,500,000` portfolio divided among RRSP, taxable, and TFSA (sized at the 4% rule: $60,000 / 0.04), plus a $60,000 cash cushion. They define success as reaching age 95 with at least their desired spending left.

Let's assume they've been working for 40 years, earning the maximum pensionable earnings each year. Depending on when they start CPP, they would receive the following **fixed** monthly amounts for life:

| Age | Amount |
| --- | ------ |
| 60  | 896    |
| 65  | 1524   |
| 70  | 2223   |

Once CPP starts, the amount remains the same (except for inflation adjustments), so the decision of when to begin has long-term consequences.

> [!TIP]
>  See https://research-tools.pwlcapital.com/research/cpp for CPP calculator that considers years worked and earnings.

In all three scenarios below, this person retires at 60. The retirement age is constant — only the CPP start age changes. This is what makes it a fair comparison: the same portfolio, the same spending, the same 35-year horizon, just different CPP timing decisions. OAS is also modelled in all three scenarios, starting at the same age as CPP — it acts as part of the overall government income picture rather than a fixed baseline.

We can run the simulation in "success rate" mode, which runs it over and over, calculating what percentage of runs result in success. Then we can modify the age at which CPP is taken to see how this affects the success rate.

At `$60,000` spending — more than half again higher than the `$40,000` lean FIRE baseline — the CPP and OAS amounts represent a smaller fraction of the total need. This makes the timing decision far more consequential, as we'll see below.

## CPP at 60

Taking CPP at 60 means smaller monthly payments — $896/month ($10,752/year) — but they start arriving immediately. That covers roughly 18% of the $60,000 annual spending from day one, with the portfolio handling the remaining 82%. OAS then adds ~$742/month from age 65 onwards. From year 5 onwards, combined guaranteed income is ~$19,656/year — about 33% of annual spending. The portfolio must still carry two-thirds of the load for the full 35-year horizon.

```bash
ruby main.rb success_rate demo/cpp_at_60.yml
```

| | |
|---|---|
| **Withdrawal Rate** | 4.0% |
| **Success Rate** | 94.6% |

| Percentile | Final Balance |
|---|---|
| 5th | $62,170 |
| 10th | $308,973 |
| 25th | $1,069,546 |
| 50th (Median) | $2,300,918 |
| 75th | $4,599,221 |
| 90th | $7,797,280 |
| 95th | $10,940,021 |

A 94.6% success rate means roughly 1 in 18 retirees in this scenario runs out of money before 95. The 5th percentile holds only $62,170 — barely one year of spending — and the 10th percentile is $309K. With two-thirds of spending unprotected by guaranteed income for the full horizon, sequence-of-returns risk bites hard in adverse scenarios. CPP arriving at day one helps at the margins, but it's not enough to cover a major shortfall in the critical early years.

The median final balance is a healthy $2.30M, and the average is $3.44M — but these aggregate numbers obscure the real story in the lower tail. For the unlucky retirees who hit bad sequence in years 1–10 without meaningful government income relief, the outcome is very tight.

## CPP at 65

Delaying CPP to 65 means no government income for the first five years — the portfolio carries the full $60,000/year load alone. In exchange, the monthly payment rises from $896 to $1,524. And since OAS also starts at 65 in this scenario, both income streams kick in simultaneously: combined guaranteed income of CPP $1,524 + OAS ~$742 = ~$2,266/month (~$27,192/year) from age 65 onwards — covering about 45% of the $60,000 annual spending need.

```bash
ruby main.rb success_rate demo/cpp_at_65.yml
```

| | |
|---|---|
| **Withdrawal Rate** | 4.0% |
| **Success Rate** | 96.6% |

| Percentile | Final Balance |
|---|---|
| 5th | $185,317 |
| 10th | $501,434 |
| 25th | $1,264,986 |
| 50th (Median) | $2,507,491 |
| 75th | $4,867,280 |
| 90th | $8,450,585 |
| 95th | $11,511,663 |

The success rate rises from 94.6% to 96.6% — about 1 in 29 retirees now fails instead of 1 in 18. More meaningful is the lower tail: the 5th percentile jumps from $62K to $185K, and the 10th from $309K to $501K. Both are still modest (roughly 3–8 years of spending), but they represent a substantially improved floor.

The five-year wait is a real cost — the portfolio faces full drawdown exposure from ages 60–64 with no government income at all. But once CPP and OAS arrive together at 65, they relieve nearly half the spending burden for the remaining 30 years. Scenarios that buckled under bad early sequence have more runway to recover. The 2-percentage-point gain in success rate reflects this structural improvement.

## CPP at 70

Delaying all the way to 70 means a full decade with no government income at all — both CPP and OAS are deferred to 70. The portfolio carries the entire $60,000/year load alone for the first decade. The payoff is the maximum CPP amount ($2,223/month) plus a deferred OAS with the full +36% bonus (~$1,010/month). Combined: ~$3,233/month (~$38,796/year) — nearly 65% of the annual spending need, arriving for the final 25 years.

```bash
ruby main.rb success_rate demo/cpp_at_70.yml
```

| | |
|---|---|
| **Withdrawal Rate** | 4.0% |
| **Success Rate** | 99.0% |

| Percentile | Final Balance |
|---|---|
| 5th | $531,786 |
| 10th | $778,962 |
| 25th | $1,447,086 |
| 50th (Median) | $2,703,435 |
| 75th | $4,772,672 |
| 90th | $7,742,322 |
| 95th | $9,575,830 |

The success rate jumps to 99.0% — roughly 1 in 100 fails, compared to 1 in 18 for CPP at 60. The lower tail transformation is striking: the 5th percentile holds $532K (nearly 9 years of spending), and the 10th percentile is $779K. These are scenarios that were genuinely dangerous under CPP at 60, now landing with substantial reserves.

The mechanism: from age 70 onwards, nearly two-thirds of spending is covered by guaranteed income. Even retirees who hit a brutal sequence in their first decade — the most damaging scenario — find that once 70 arrives, the portfolio's workload drops so sharply that it can recover. The 25 remaining years of 65% income coverage neutralize the damage that sequence risk inflicts in years 1–10.

The full decade of zero government income is a real risk: the portfolio must survive 10 years of unassisted drawdown before any relief arrives. But the $1.5M starting portfolio (sized at 4% of spending) is specifically designed to absorb this. The GBM stress-test confirms it holds up.

## The Bottom Line

| CPP Start Age | Monthly CPP | OAS Start Age | Monthly OAS | Govt Income Coverage | Success Rate |
|---|---|---|---|---|---|
| 60 | $896 | 65 | ~$742 | 33% (from age 65) | 94.6% |
| 65 | $1,524 | 65 | ~$742 | 45% (from age 65) | 96.6% |
| 70 | $2,223 | 70 | ~$1,010 | 65% (from age 70) | 99.0% |

At a realistic $60,000 spending level for a single HCOL retiree, CPP timing is no longer a subtle question — it's a 4.4-percentage-point spread between the worst and best strategies. The difference between CPP at 60 and CPP at 70 is roughly the difference between 1-in-18 failure odds and 1-in-100 failure odds.

The key reason is structural: $60,000 in spending is large enough that CPP and OAS at their early amounts don't meaningfully reduce portfolio risk. At 60, the combined government income covers only 33% of spending from age 65 — leaving the portfolio carrying two-thirds of the load indefinitely. At 70, it covers 65%, and the portfolio's remaining role is manageable even in adverse markets.

The case for taking CPP early — "take the money while you can" — has genuine appeal psychologically, but at this spending level the numbers push clearly in the other direction. Every year of delay buys not just a higher monthly cheque but a meaningfully safer retirement, particularly in the lower tail where failure actually happens.

The 5-to-70 gap in the 5th percentile — $62K vs. $532K — is perhaps the starkest way to see it. Both retirees started with the same $1.5M. The one who took CPP at 60 ends their 35-year retirement with barely a year of spending left; the one who waited ends with nearly nine. Government income timing, not portfolio performance, made the difference.

For those with sufficient savings to bridge the gap: delay CPP as long as possible. At a comfortable HCOL spending level, the math is not close.

> [!NOTE]
> The absolute success rates here are lower than historical replay studies would show — by design. See [how it works](../how-it-works.md#geometric_brownian_motion-recommended) for a full explanation of how this simulator's GBM model acts as a stress test rather than a historical backtest. The case for 70 is strongest if you're focused on the lower tail (where the improvement is clearest) and if you have enough portfolio to sustain a decade of full drawdown without taking on excessive sequence-of-returns risk in the process.

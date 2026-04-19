# Does a Life Annuity Actually Help?

## Contents

- [Does a Life Annuity Actually Help?](#does-a-life-annuity-actually-help)
  - [Contents](#contents)
  - [The Setup: A Plan That Almost Works](#the-setup-a-plan-that-almost-works)
  - [Without an Annuity: Probably Fine](#without-an-annuity-probably-fine)
  - [Adding a $100K Annuity](#adding-a-100k-annuity)
  - [Key Takeaways](#key-takeaways)

Many Canadians dismiss annuities as "giving away their money." Yet the math behind them is compelling: the **mortality credit** — where those who die early subsidize those who live long — allows insurers to pay out roughly 6.5–7% annually at age 65, compared to the commonly cited 4% "safe" withdrawal rate from a portfolio. No investment strategy can replicate this, because it's not an investment return — it's a fundamentally different source of income based on pooled longevity risk.

The question: does this actually show up in simulations? And does it matter for someone whose plan is already in reasonable shape?

## The Setup: A Plan That Almost Works

Consider someone retiring at 65 with a $1.15M portfolio (RRSP $700K, Taxable $250K, TFSA $150K, Cash Cushion $50K) who needs $50,000/year in spending. Their guaranteed income — CPP at $800/month starting at 65, plus full OAS — covers about $18,500/year, or 37% of their spending need. The portfolio has to generate the remaining ~$31,500/year.

That works out to a withdrawal rate of about 4.6% — slightly above the traditional 4% "safe" withdrawal rate. Not alarming, but not bulletproof either.

All scenarios: 1,000 runs, geometric Brownian motion, 60/40 returns (average 4%, min -25%, max 35%), max age 95, success factor 1.

## Without an Annuity: Probably Fine

```bash
ruby main.rb success_rate demo/annuity_insight_no_annuity.yml
```

| | |
|---|---|
| **Withdrawal Rate** | 4.6% |
| **Success Rate** | ~91% |

| Percentile | Final Balance |
|---|---|
| 5th | ~$38,000 |
| 10th | ~$69,000 |
| 25th | ~$428,000 |
| 50th (Median) | ~$990,000 |
| 75th | ~$1,874,000 |
| 90th | ~$2,972,000 |
| 95th | ~$3,915,000 |

A ~91% success rate sounds good — 9 out of 10 simulations make it to age 95. But that also means roughly 1 in 10 don't. And the lower tail tells the real story: the 5th percentile ends with just $38K (less than one year of spending), and the 10th percentile at $69K. These are the scenarios where a bad sequence of returns in the first few years drains the portfolio faster than it can recover.

## Adding a $100K Annuity

Same person, but at age 65 they convert $100K of their RRSP to a life annuity paying $580/month (~$580 per $100K, male age 65 rates as of April 2026).

After the purchase: RRSP drops from $700K to $600K, total investable portfolio is effectively $1.05M. But the annuity provides $6,960/year of guaranteed income. Combined guaranteed income is now: CPP ($9,600) + OAS (~$8,900) + Annuity ($6,960) = ~$25,460/year — covering **51% of $50K spending**, up from 37%.

```bash
ruby main.rb success_rate demo/annuity_insight_with_annuity.yml
```

| | |
|---|---|
| **Withdrawal Rate** | 4.6% |
| **Success Rate** | ~96% |

| Percentile | Final Balance |
|---|---|
| 5th | ~$75,000 |
| 10th | ~$188,000 |
| 25th | ~$501,000 |
| 50th (Median) | ~$1,072,000 |
| 75th | ~$1,939,000 |
| 90th | ~$3,207,000 |
| 95th | ~$3,979,000 |

**Success rate jumps from ~91% to ~96%** — the difference between "1 in 10 fail" and "1 in 25 fail." But the percentile shifts are even more revealing:

| Percentile | No Annuity | With Annuity | Change |
|---|---|---|---|
| 5th | ~$38,000 | ~$75,000 | +97% |
| 10th | ~$69,000 | ~$188,000 | +172% |
| 25th | ~$428,000 | ~$501,000 | +17% |
| 50th | ~$990,000 | ~$1,072,000 | +8% |
| 75th | ~$1,874,000 | ~$1,939,000 | +3% |

The pattern is clear: the annuity helps the lower tail dramatically and barely affects the upper tail. The 10th percentile nearly triples — from barely surviving to having almost four years of spending in reserve. Meanwhile, the 75th and 95th percentiles are essentially unchanged, because the $100K that was annuitized is a small fraction of the portfolio in scenarios where markets performed well.

This is the annuity's value proposition in a nutshell: you're trading a tiny amount of upside in the good scenarios for substantially better outcomes in the bad ones. Converting less than 9% of the portfolio to guaranteed income cut the failure rate by more than half.

## Key Takeaways

- **A modest annuity can meaningfully improve a borderline plan.** Converting just $100K — less than 9% of the portfolio — improved the success rate from ~91% to ~96% and nearly tripled the 10th percentile final balance.
- **The benefit comes from the mortality credit.** The insurer pays ~7% annually because longevity risk is pooled across annuitants. No safe investment strategy can replicate this.
- **The annuity helps the lower tail most.** The worst-case scenarios improve dramatically while the best-case scenarios are barely affected. You're giving up a small amount of upside to substantially reduce downside risk.
- **The capital is irrevocably gone.** If you die early, you "lose". If you live long, you "win." This is the psychological barrier that keeps many Canadians from considering annuities — and it's exactly the tradeoff that makes the math work.
- **Limitation:** This simulator does not model inflation. Non-indexed annuity payments lose purchasing power over time, which is not captured here — so the results slightly overstate the annuity's long-term benefit.

> [!NOTE]
> All success rates shown are approximate. Geometric Brownian Motion simulations produce different results each run. Run the scenarios multiple times to get a sense of the range. The directional conclusions (annuity improves success rate, especially in the lower tail) are robust across runs.

# TFSA Contributions During Drawdown: Does It Help?

## Contents

- [Why It's Not Obvious](#why-its-not-obvious)
- [The Setup](#the-setup)
- [$60,000/year Spending (Realistic HCOL)](#60000year-spending-realistic-hcol)
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

One variable that matters: your tax bracket. If your spending is low enough that even with the TFSA contribution you stay in a relatively low bracket, the upfront tax cost is smaller and the tradeoff might look different than for someone whose total withdrawal is already in a higher bracket.

To make that concrete for the scenarios below: in Ontario, the combined federal + provincial marginal rate sits at roughly 20.1% up to about $52,000 of gross income, then jumps to about 24.1%. CPP and OAS are both taxable income, but they reduce the RRSP withdrawal needed to hit the same take-home target — so total gross income (RRSP + CPP + OAS) stays approximately the same as without OAS. What changes is composition, not total.

At $60,000 spending, the gross income needed already sits well into the 24.1% bracket — roughly $75,000–$78,000 total — before any TFSA contribution is considered. Adding the $7,000 TFSA contribution on top pushes the required RRSP withdrawal higher, but stays within the same 24.1% bracket. The marginal tax cost of every dollar shifted to the TFSA is 24.1%.

At $35,000 spending, both scenarios stay within the 20.1% bracket: roughly $39,900 gross without the contribution and $48,700 with it. The marginal tax cost of shifting money to the TFSA is 20.1% throughout.

The result is a clean comparison: higher spending → higher marginal tax cost of the TFSA contribution → worse tradeoff. Lower spending (by design) → lower marginal tax cost → the contribution has a fighting chance.

## The Setup

All scenarios use a Canadian retiree profile: retiring at 65, running to 95 (30-year horizon), CPP of $800/month (roughly the average for someone taking CPP at 65) plus full OAS of ~$742/month, both starting at 65, and a 60/40 stock/bond portfolio. The withdrawal rate is set at 3.5% — slightly more conservative than the classic 4% rule — by sizing the portfolio accordingly. The TFSA contribution amount is $7,000/year, the 2024–2025 annual limit.

## $60,000/year Spending (Realistic HCOL)

Investable portfolio (RRSP + Taxable + TFSA) sized to a 3.5% withdrawal rate: $60,000 ÷ 0.035 ≈ **$1,714,000**, plus a $60,000 cash cushion on top. Combined guaranteed income from CPP and OAS of ~$1,542/month ($18,500/year) covers about 31% of the $60,000 spending need — the portfolio must carry the remaining 69%.

With the TFSA contribution, the portfolio must effectively fund $67,000/year equivalent — the extra gross RRSP withdrawal needed to cover both spending and the contribution after tax, all drawn at the 24.1% marginal rate.

### Without TFSA Contribution

```bash
ruby main.rb success_rate demo/tfsa_drawdown_60k.yml
```

| | |
|---|---|
| **Withdrawal Rate** | 3.5% |
| **Success Rate** | 97.2% |

| Percentile | Final Balance |
|---|---|
| 5th | $155,621 |
| 10th | $402,291 |
| 25th | $898,018 |
| 50th (Median) | $1,862,412 |
| 75th | $3,230,673 |
| 90th | $5,589,856 |
| 95th | $7,399,020 |

A 97.2% success rate is a solid baseline for a $60K HCOL retirement: roughly 1 in 36 retirees runs out before 95. The 5th percentile holds $156K — about 2.6 years of spending — and the median ends at $1.86M. CPP and OAS together cover 31% of annual spending, which meaningfully reduces sequence-of-returns exposure, but the portfolio still does the heavy lifting. With a conservative 3.5% withdrawal rate, the gap between the realistic worst and median outcomes is manageable.

### With $7,000/year TFSA Contribution

Everything identical to the scenario above, except `annual_tfsa_contribution: 7000` is added on top of the $60,000 spending. The portfolio must now fund both.

```bash
ruby main.rb success_rate demo/tfsa_drawdown_60k_contrib.yml
```

| | |
|---|---|
| **Withdrawal Rate** | 3.5% |
| **Success Rate** | 96.0% |

| Percentile | Final Balance |
|---|---|
| 5th | $116,485 |
| 10th | $341,211 |
| 25th | $901,923 |
| 50th (Median) | $1,795,526 |
| 75th | $3,376,263 |
| 90th | $6,112,017 |
| 95th | $8,372,876 |

The success rate drops from 97.2% to 96.0% — a 1.2 percentage point loss. The lower tail deteriorates: the 5th percentile falls from $156K to $116K (a 25% drop) and the 10th from $402K to $341K. The median slips from $1.86M to $1.80M. The portfolio is being drawn on more aggressively each year to fund the TFSA, and at the 24.1% marginal tax rate, the upfront cost is real. The future tax-free benefit doesn't compensate within a 30-year window for the scenarios that are already under pressure.

The upper tail tells the opposite story: the 95th percentile rises from $7.4M to $8.4M. Tax-free compounding over 30 years delivers for the scenarios where the portfolio grows strongly and never faces a survival crisis. But those scenarios didn't need help — and the 1.2pp success rate loss shows the cost is paid by the retirees who could least afford it.

## $35,000/year Spending (Lower Tax Bracket)

Investable portfolio sized to a 3.5% withdrawal rate: $35,000 ÷ 0.035 = **$1,000,000** exactly, plus a $35,000 cash cushion on top. This is an intentionally lower spending target — one that keeps total gross income in the 20.1% marginal bracket throughout, including when the TFSA contribution is added. As described above, both the baseline (~$39,900 gross) and the contribution scenario (~$48,700 gross) stay comfortably below the ~$52,000 bracket threshold. If the marginal tax rate argument has any force, it should show up here.

### Without TFSA Contribution

```bash
ruby main.rb success_rate demo/tfsa_drawdown_35k.yml
```

| | |
|---|---|
| **Withdrawal Rate** | 3.5% |
| **Success Rate** | 99.7% |

| Percentile | Final Balance |
|---|---|
| 5th | $377,885 |
| 10th | $536,014 |
| 25th | $935,879 |
| 50th (Median) | $1,639,826 |
| 75th | $2,674,115 |
| 90th | $4,080,824 |
| 95th | $5,320,303 |

A 99.7% success rate — the combination of low spending, a conservative 3.5% withdrawal rate, and CPP+OAS covering a larger fraction of expenses pushes the outcome very close to the ceiling. The 5th percentile holds $378K — more than ten years of spending — and the median is $1.64M. Sequence-of-returns risk has relatively little room to cause damage when guaranteed income handles most of the annual need.

### With $7,000/year TFSA Contribution

Everything identical to the scenario above, except `annual_tfsa_contribution: 7000` is added on top of the $35,000 spending.

```bash
ruby main.rb success_rate demo/tfsa_drawdown_35k_contrib.yml
```

| | |
|---|---|
| **Withdrawal Rate** | 3.5% |
| **Success Rate** | 99.8% |

| Percentile | Final Balance |
|---|---|
| 5th | $310,343 |
| 10th | $509,662 |
| 25th | $879,711 |
| 50th (Median) | $1,553,805 |
| 75th | $2,733,859 |
| 90th | $4,218,227 |
| 95th | $5,338,255 |

The success rate is essentially unchanged at 99.8% — both scenarios are at the ceiling and the 0.1pp difference is within simulation noise. The lower-tail percentiles show some variability: the 5th percentile fell from $378K to $310K in this run, which reflects the noisiness of outcomes near the ceiling rather than a meaningful signal. At 99.7%/99.8%, both strategies are in the same territory — the distribution of final balances is the more useful lens.

The median and upper percentiles are slightly lower with the contribution, which is expected: more RRSP is drawn each year, so the compounding base is smaller. But with the contribution staying in the 20.1% bracket, the upfront tax cost is lower than the $60K scenario, and the survival odds don't suffer. The key contrast with the $60K case is the marginal rate: here, every dollar shifted to the TFSA costs 20.1% in immediate tax, not 24.1%. At the ceiling, that difference doesn't move the survival needle — but it doesn't hurt it either.

## Early Retirement (FIRE): Does the Longer Horizon Change Things?

The two scenarios above use a 30-year retirement horizon (age 65 to 95). What about retiring at 45 with a 50-year horizon? The extra decades of tax-free compounding could change the calculus significantly — and the question of whether the benefit eventually outstrips the upfront tax cost becomes much more plausible when there are 50 years for it to play out.

Same $60,000 spending and $1,714,000 investable portfolio as the first section (3.5% withdrawal rate), but retiring at 45 with 100% equity returns and modest CPP of $500/month at 65 plus OAS of ~$742/month from 65 — roughly what 20 years of median-income work earns. The portfolio carries the full $60K/year load for 20 years before CPP and OAS arrive together, at which point government income covers only ~25% of spending ($14,900/year combined).

### Without TFSA Contribution

```bash
ruby main.rb success_rate demo/tfsa_drawdown_fire.yml
```

| | |
|---|---|
| **Withdrawal Rate** | 3.5% |
| **Success Rate** | 64.0% |

| Percentile | Final Balance |
|---|---|
| 5th | $7,735 |
| 10th | $15,254 |
| 25th | $32,467 |
| 50th (Median) | $1,514,390 |
| 75th | $9,002,704 |
| 90th | $24,617,202 |
| 95th | $38,565,810 |

A 64.0% success rate — much lower than either standard retirement scenario, which is expected. A 50-year horizon with no income support for the first 20 years and $60K spending is a significantly harder problem than a 30-year horizon with CPP and OAS from day one. The distribution shows the extreme bimodality of long 100% equity simulations: the 25th percentile is $32K while the 75th is $9M. The scenarios that survive compound into very large numbers over 50 years; the ones that fail tend to fail decisively in the first decade.

### With $7,000/year TFSA Contribution

Everything identical, with `annual_tfsa_contribution: 7000` added on top of $60,000 spending.

```bash
ruby main.rb success_rate demo/tfsa_drawdown_fire_contrib.yml
```

| | |
|---|---|
| **Withdrawal Rate** | 3.5% |
| **Success Rate** | 60.1% |

| Percentile | Final Balance |
|---|---|
| 5th | $6,611 |
| 10th | $12,786 |
| 25th | $31,061 |
| 50th (Median) | $1,230,414 |
| 75th | $7,300,169 |
| 90th | $18,500,941 |
| 95th | $34,105,414 |

The success rate falls from 64.0% to 60.1% — a 3.9 percentage point drop. At 1,000 simulation runs, this is outside noise range and represents a genuine signal: the TFSA contribution meaningfully hurts FIRE survival odds at $60K spending. The median falls from $1.51M to $1.23M, and the upper percentiles are lower across the board (95th: $38.6M → $34.1M). Even the best-case survivors end up with less.

The mechanism is the same one that shows up in the standard retirement case, but amplified by two factors. First, the portfolio must carry the full $60K/year for 20 years with zero income support — each extra dollar of RRSP withdrawal for the TFSA contribution represents compounding foregone during exactly the most damaging window for sequence-of-returns risk. Second, at $60K spending the RRSP withdrawal already sits at the 24.1% marginal rate from the start, so the TFSA contribution has a high immediate tax cost throughout those 20 critical years. The 50 years of tax-free compounding on the money that makes it to the TFSA is not enough to overcome a 3.9pp survival penalty in the scenarios that need it most.

## What We Found

The picture across three spending levels is coherent and the pattern is clear.

In the **30-year standard retirement at $60K** (realistic HCOL), the TFSA contribution costs 1.2 percentage points of success rate (97.2% → 96.0%) and worsens the lower tail — the 5th percentile drops from $156K to $116K. The portfolio is already drawing at the 24.1% marginal rate without the contribution, so every dollar shifted to the TFSA carries that full immediate tax cost. Over 30 years, the tax-free compounding benefit doesn't recoup it in the scenarios under stress.

In the **30-year standard retirement at $35K** (intentional low-bracket strategy), success rates are statistically identical — 99.7% vs 99.8%, both at the ceiling. At the 20.1% marginal rate, the TFSA contribution is cheaper per dollar shifted, and the lower spending means the portfolio is under far less pressure to begin with. The strategy is neutral on survival odds, which means the legitimate non-survival reasons to contribute (RRIF reduction, OAS clawback management, estate planning) can drive the decision without worrying about a survival cost.

In the **50-year FIRE scenario at $60K**, the TFSA contribution produces a clear -3.9pp drop in success rate (64.0% → 60.1%) — a meaningful signal beyond simulation noise. The 20-year period without any CPP or OAS income means the portfolio's full drawdown burden falls on the invested accounts alone, and funding an annual TFSA contribution on top of $60K spending adds a compounding drag precisely when the portfolio is most vulnerable. The 50-year horizon does not redeem the strategy — the tax-free growth over decades is outweighed by the higher portfolio exposure in the critical first two decades.

## Key Takeaways

1. **At higher spending ($60K), the TFSA contribution hurts survival odds in standard retirement.** The -1.2pp success rate gap and the deteriorating lower tail reflect the 24.1% marginal tax cost of drawing extra RRSP income at this spending level. The upper tail benefits — tax-free compounding does pay off for the scenarios that never face a survival crisis — but the cost falls on the retirees who need protection most.
2. **At lower spending ($35K), the TFSA contribution is neutral on survival odds.** Both scenarios sit at the ceiling (~99.7–99.8%). At the 20.1% marginal rate, the upfront tax cost is lower and the strategy neither helps nor hurts survival odds. The legitimate non-survival reasons to contribute — reducing RRIF forced withdrawals at 71, managing OAS clawback, estate planning, or tax diversification — can drive the decision without a survival penalty.
3. **In FIRE at $60K, the TFSA contribution clearly hurts.** The -3.9pp drop is outside simulation noise. During the 20-year window before CPP and OAS arrive, each extra dollar of RRSP withdrawal for the contribution compounds the drawdown burden at the worst possible time.
4. **The tax bracket is the key lever.** Lower spending → lower marginal rate on RRSP withdrawals → cheaper to fund the TFSA → survival odds unaffected. Higher spending → already in the upper bracket → higher immediate cost → survival penalty. The question isn't whether the TFSA contribution is a good idea in isolation; it's what marginal tax rate you pay to fund it.
5. **This doesn't mean avoiding the strategy.** There are legitimate reasons to shift money from RRSP to TFSA during drawdown: reducing RRIF forced withdrawals at 71, minimizing OAS clawback (not yet modelled by this simulator), estate planning, or tax diversification. Those benefits are real — they just don't show up in a success rate metric. If one of those goals matters to you, the survival cost at lower spending levels is small enough that it needn't be a barrier. At higher spending levels, weigh the cost consciously.

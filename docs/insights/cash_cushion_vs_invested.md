# Cash Cushion vs. Keeping It Invested

## Contents

- [The Tradeoff](#the-tradeoff)
- [The Setup](#the-setup)
- [Standard Retirement (30-Year Horizon)](#standard-retirement-30-year-horizon)
  - [With 1-Year Cash Cushion](#with-1-year-cash-cushion)
  - [Without Cash Cushion (Fully Invested)](#without-cash-cushion-fully-invested)
- [Early Retirement (50-Year Horizon)](#early-retirement-50-year-horizon)
  - [With 1-Year Cash Cushion](#with-1-year-cash-cushion-1)
  - [Without Cash Cushion (Fully Invested)](#without-cash-cushion-fully-invested-1)
- [What We Found](#what-we-found)
- [Key Takeaways](#key-takeaways)

## The Tradeoff

The cash cushion is one of the most discussed tools in retirement planning. The idea: keep one to two years of spending in a liquid, low-risk account (like a HISA or short-term GICs). When the market drops severely, withdraw from the cash cushion instead of selling investments at a loss. Give the portfolio time to recover before you need to touch it again.

It sounds sensible. But there's an obvious counter-argument: that cash is sitting in a savings account earning well under 3% — EQ Bank's everyday savings rate sits at around 1% for most users, with higher rates requiring conditions a retiree drawing down may not meet — while it could be invested earning your portfolio's long-run average. Is the downside protection worth the drag?

In this simulator, the cash cushion activates when the annual market return falls below `downturn_threshold` (set to −10% in the scenarios below). In those years, spending is covered by the cash cushion instead of the portfolio. Once depleted, the cushion is gone for the rest of the simulation — it is not refilled.

> [!NOTE]
> The comparison is only fair if total money is held constant. Adding a cash cushion on top of the same invested portfolio would give the cushion scenario more money overall — an unfair advantage. Instead, both scenarios start with the same $1,560,000 total: the cushion scenario holds $1,500,000 invested + $60,000 in cash; the no-cushion scenario holds $1,560,000 fully invested.
>
> The reported withdrawal rate will differ slightly between the two scenarios. The simulator calculates withdrawal rate using only the invested portfolio as the denominator — the cash cushion is excluded. So the cushion scenario shows 4.0% ($60,000 ÷ $1,500,000) while the no-cushion scenario shows ~3.85% ($60,000 ÷ $1,560,000). This is expected: the $60,000 in cash isn't part of the compounding base, so it shouldn't be part of the withdrawal rate denominator either.

## The Setup

All scenarios use $60,000/year spending (a modest but realistic budget for a single person in a high-cost-of-living city like Vancouver or Toronto) and the same $1,560,000 total. The cushion scenarios allocate $60,000 (one year of spending) to cash and the remaining $1,500,000 to invested accounts; the no-cushion scenarios put all $1,560,000 into invested accounts. Accounts maintain the same 60/20/20 RRSP/Taxable/TFSA split across both versions.

Standard retirement uses 60/40 stock/bond returns (average 4%, consistent with the other 30-year scenarios). Early retirement uses 100% equity (average 5%), consistent with the FIRE scenarios — a higher-volatility setting where the cash cushion has more chances to activate. OAS is modelled in all scenarios: full pension (~$742/month) from age 65 for the standard retirement cases, and from 65 for the FIRE cases (20 years into retirement for someone retiring at 45).

## Standard Retirement (30-Year Horizon)

Retiring at 65, running to 95, CPP of $800/month plus OAS of ~$742/month from age 65. Combined guaranteed income of ~$1,542/month ($18,500/year) covers about 31% of the $60,000 annual spending need — the portfolio must still carry nearly 70% of the load.

### With 1-Year Cash Cushion

```bash
ruby main.rb success_rate demo/cash_cushion_with.yml
```

| | |
|---|---|
| **Withdrawal Rate** | 4.0% |
| **Success Rate** | 92.7% |

| Percentile | Final Balance |
|---|---|
| 5th | $46,904 |
| 10th | $163,266 |
| 25th | $597,825 |
| 50th (Median) | $1,355,903 |
| 75th | $2,696,733 |
| 90th | $4,414,805 |
| 95th | $5,664,077 |

A 92.7% success rate with a meaningful lower tail. The 5th percentile holds $47K — less than a year of spending — but the 10th is $163K, providing some runway. At $60K spending, guaranteed income covers only 31% of annual expenses (vs 46% in a $40K scenario), so the portfolio is under considerably more pressure. The cash cushion absorbs the worst early-downturn years and provides just enough buffer to shift marginal failures into survivors.

### Without Cash Cushion (Fully Invested)

```bash
ruby main.rb success_rate demo/cash_cushion_without.yml
```

| | |
|---|---|
| **Withdrawal Rate** | 3.85% |
| **Success Rate** | 91.2% |

| Percentile | Final Balance |
|---|---|
| 5th | $25,600 |
| 10th | $133,185 |
| 25th | $646,169 |
| 50th (Median) | $1,447,473 |
| 75th | $2,816,828 |
| 90th | $4,643,911 |
| 95th | $6,125,805 |

The success rate drops to 91.2% — a 1.5 percentage point gap, the clearest signal seen between the cushion and no-cushion versions in this comparison. The lower tail is more exposed: the 5th percentile falls from $47K to $26K (roughly half), and the 10th from $163K to $133K. Without the cushion, bad early-sequence years force selling into the decline, and with two-thirds of spending unprotected by guaranteed income, those losses compound harder.

The upper tail flips, as expected: the 95th percentile is $6.1M without the cushion vs $5.7M with it. The $60K that stays invested rather than sitting in cash at ~1% earns its long-run average over 30 years, and it shows at the top.

## Early Retirement (50-Year Horizon)

Retiring at 45, running to 95, 100% equity, CPP of $500/month at 65 plus OAS of ~$742/month from age 65. The portfolio carries the full $60K/year load for 20 years before either income stream arrives, and the 100% equity allocation means more frequent and more severe downturns — more opportunities for the cash cushion to activate. Even once government income arrives at 65, it covers only ~25% of spending ($14,900/year from CPP and OAS combined), leaving the portfolio doing the heavy lifting throughout.

### With 1-Year Cash Cushion

```bash
ruby main.rb success_rate demo/cash_cushion_fire_with.yml
```

| | |
|---|---|
| **Withdrawal Rate** | 4.0% |
| **Success Rate** | 53.9% |

| Percentile | Final Balance |
|---|---|
| 5th | $6,479 |
| 10th | $11,318 |
| 25th | $27,352 |
| 50th (Median) | $320,713 |
| 75th | $4,859,373 |
| 90th | $15,110,446 |
| 95th | $26,617,951 |

The extreme bimodality of long 100% equity simulations is on full display: the 25th percentile is $27K while the 75th is $4.9M. The success rate sits at 53.9% — just above a coin flip. A 4% withdrawal rate over a 50-year horizon with 100% equity and $60K spending is a challenging proposition, and the results reflect it. The lower tail is effectively zero across the 5th and 10th percentiles — those scenarios experienced catastrophic early-decade collapses and ran out years before CPP or OAS could help.

### Without Cash Cushion (Fully Invested)

```bash
ruby main.rb success_rate demo/cash_cushion_fire_without.yml
```

| | |
|---|---|
| **Withdrawal Rate** | 3.85% |
| **Success Rate** | 52.0% |

| Percentile | Final Balance |
|---|---|
| 5th | $7,139 |
| 10th | $12,585 |
| 25th | $26,821 |
| 50th (Median) | $323,299 |
| 75th | $5,336,467 |
| 90th | $18,206,840 |
| 95th | $32,470,885 |

The success rate is 52.0% — 1.9 percentage points below the cushion scenario, but within simulation noise. The median is nearly identical ($323K vs $321K). The lower tail is also essentially unchanged — both near zero — because the failures in this scenario are total collapses from the first decade, happening years before any government income arrives. One year of spending in cash cannot prevent that kind of structural failure.

The upper tail diverges sharply: the 95th percentile is $32.5M without the cushion vs $26.6M with it — a $6M difference. The average is $6.7M vs $5.3M. That $60K compounding at 5% average over 50 years with 100% equity creates enormous upside for the scenarios that survive. The cushion's opportunity cost is highest here.

## What We Found

The two retirement horizons produce different results, but they tell a coherent story about what the cushion is actually protecting against.

In the **30-year standard retirement** scenario, the cash cushion delivers a clear benefit: 92.7% vs 91.2% success rate — a 1.5 percentage point gap that's more than simulation noise. The lower tail confirms it: the 5th percentile is $47K with the cushion vs $26K without — nearly double. At $60K spending, the portfolio carries nearly 70% of annual expenses because CPP and OAS together cover only 31% of spending. That higher portfolio dependency makes sequence-of-returns risk more damaging, and the cushion directly addresses it. This is a more stressed scenario than the $40K equivalent, and the cushion's benefit is correspondingly clearer.

In the **50-year FIRE** scenario, the cushion provides no meaningful advantage on success rate — 53.9% vs 52.0%, within simulation noise. The lower tail is identical either way (near zero), because the failures are catastrophic early-decade collapses that a one-year cash buffer cannot save. The upside sharply favours being fully invested: 95th percentile $32.5M vs $26.6M. A 4% withdrawal rate over 50 years with 100% equity and $60K spending is a genuinely difficult proposition — the ~53% success rate reflects that this sits right at the edge of what this strategy can reliably sustain.

The difference comes down to what kind of risk the cash cushion actually addresses. In the 30-year scenario, the main threat is a bad first few years combined with forced selling — sequence-of-returns risk. The portfolio size and horizon are both in a range where recovering from a bad start is possible given the cushion's protection. In the 50-year 100% equity scenario, the failures tend to be total collapses from the first decade that no buffer can recover. The cushion can't save those outcomes, and it extracts a large opportunity cost from the scenarios that do succeed.

## Key Takeaways

1. **In standard retirement (30-year, 60/40), the cash cushion shows a clear benefit.** The 1.5 percentage point success rate gap (92.7% vs 91.2%) is the largest seen in this comparison, and the lower tail confirms it — the 5th percentile holds nearly twice as much with the cushion ($47K vs $26K). At $60K spending, with guaranteed income covering only 31% of expenses, the portfolio is under real pressure and the cushion earns its keep.
2. **In early retirement (50-year, 100% equity), the cash cushion is neutral on success rate** — 53.9% with vs 52.0% without, within simulation noise. The lower tail is identical either way (near zero). The upper tail strongly favours being fully invested — the 95th percentile is $32.5M without the cushion vs $26.6M with it.
3. **The cushion works when it can prevent failure; it doesn't when failure is already inevitable.** A bad first few years in a 30-year 60/40 portfolio is recoverable with the right buffer. A catastrophic 100% equity collapse in the first decade of a 50-year horizon isn't — and one year of spending in cash makes no difference either way.
4. **The opportunity cost compounds over time.** $60K kept in a Canadian savings account at ~1% vs invested at 5% average is a meaningful difference over 30 years. Over 50 years with 100% equity, it's enormous — and the FIRE results show it clearly in the upper percentiles.
5. **A 4% withdrawal rate over 50 years is genuinely hard.** The FIRE scenarios land near 53–54% success — essentially a coin flip. Retirees targeting this horizon with $60K spending should consider whether to build a larger initial portfolio, reduce spending, or accept that some sequence-of-returns scenarios will end in failure despite best efforts.

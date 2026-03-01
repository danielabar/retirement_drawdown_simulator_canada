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
> The comparison is only fair if total money is held constant. Adding a cash cushion on top of the same invested portfolio would give the cushion scenario more money overall — an unfair advantage. Instead, both scenarios start with the same $1,183,000 total: the cushion scenario holds $1,143,000 invested + $40,000 in cash; the no-cushion scenario holds $1,183,000 fully invested.
>
> The reported withdrawal rate will differ slightly between the two scenarios. The simulator calculates withdrawal rate using only the invested portfolio as the denominator — the cash cushion is excluded. So the cushion scenario shows 3.5% ($40,000 ÷ $1,143,000) while the no-cushion scenario shows ~3.38% ($40,000 ÷ $1,183,000). This is expected: the $40,000 in cash isn't part of the compounding base, so it shouldn't be part of the withdrawal rate denominator either.

## The Setup

All scenarios use $40,000/year spending and the same $1,183,000 total. The cushion scenarios allocate $40,000 (one year of spending) to cash and the remaining $1,143,000 to invested accounts; the no-cushion scenarios put all $1,183,000 into invested accounts. Accounts maintain the same 60/20/20 RRSP/Taxable/TFSA split across both versions.

Standard retirement uses 60/40 stock/bond returns (average 4%, consistent with the other 30-year scenarios). Early retirement uses 100% equity (average 5%), consistent with the FIRE scenarios — a higher-volatility setting where the cash cushion has more chances to activate.

## Standard Retirement (30-Year Horizon)

Retiring at 65, running to 95, CPP of $800/month.

### With 1-Year Cash Cushion

```bash
ruby main.rb success_rate demo/cash_cushion_with.yml
```

| | |
|---|---|
| **Withdrawal Rate** | 3.5% |
| **Success Rate** | 95.9% |

| Percentile | Final Balance |
|---|---|
| 5th | $104,438 |
| 10th | $284,091 |
| 25th | $624,097 |
| 50th (Median) | $1,299,908 |
| 75th | $2,224,816 |
| 90th | $3,623,971 |
| 95th | $4,770,184 |

A 95.9% success rate with a notably strong lower tail: the 5th percentile holds $104K — more than two years of spending — and the 10th is $284K. The cash cushion is doing exactly what it's designed to do: absorbing the bad years early in retirement without forcing the portfolio to sell at a loss. That protection shows up most clearly at the bottom of the distribution, where sequence-of-returns risk hits hardest.

### Without Cash Cushion (Fully Invested)

```bash
ruby main.rb success_rate demo/cash_cushion_without.yml
```

| | |
|---|---|
| **Withdrawal Rate** | 3.38% |
| **Success Rate** | 94.7% |

| Percentile | Final Balance |
|---|---|
| 5th | $39,211 |
| 10th | $175,572 |
| 25th | $570,098 |
| 50th (Median) | $1,233,206 |
| 75th | $2,363,165 |
| 90th | $3,926,745 |
| 95th | $5,257,911 |

The success rate drops to 94.7% — 1.2 percentage points lower than the cushion scenario. At 1,000 simulations, the margin of error on a single run is roughly ±1%, so the success rate difference alone is within noise and shouldn't be read as a firm conclusion. The lower tail is where the clearer signal is: the 5th percentile falls from $104K to $39K, and the 10th from $284K to $176K. That's a large enough economic difference to be meaningful. Without a buffer, bad early years force selling into a down market, and those losses compound over the remaining decades of the simulation.

The upper tail flips. The 75th, 90th, and 95th percentiles are all higher without the cushion — by meaningful amounts at the top (95th: $5.26M vs $4.77M). That extra $40K in the portfolio has been compounding for 30 years instead of sitting in savings earning ~1%, and in the good scenarios it shows. The cash cushion costs you upside to buy downside protection — and the lower tail improvement is the main evidence that the protection is worth the cost.

## Early Retirement (50-Year Horizon)

Retiring at 45, running to 95, 100% equity, CPP of $500/month at 65. The portfolio carries the full $40K/year load for 20 years before CPP arrives, and the 100% equity allocation means more frequent and more severe downturns — more opportunities for the cash cushion to activate.

### With 1-Year Cash Cushion

```bash
ruby main.rb success_rate demo/cash_cushion_fire_with.yml
```

| | |
|---|---|
| **Withdrawal Rate** | 3.5% |
| **Success Rate** | 59.3% |

| Percentile | Final Balance |
|---|---|
| 5th | $5,073 |
| 10th | $9,725 |
| 25th | $23,344 |
| 50th (Median) | $729,473 |
| 75th | $5,359,986 |
| 90th | $15,150,852 |
| 95th | $24,421,395 |

The extreme bimodality of long 100% equity simulations is on full display here: the 25th percentile is essentially zero ($23K) while the 75th is $5.4M. The cash cushion holds the success rate at 59.3% — but compared to the 30-year case, the lower tail is no longer meaningfully protected. The 5th percentile is $5K — both effectively zero whether or not the cushion is there.

### Without Cash Cushion (Fully Invested)

```bash
ruby main.rb success_rate demo/cash_cushion_fire_without.yml
```

| | |
|---|---|
| **Withdrawal Rate** | 3.38% |
| **Success Rate** | 60.6% |

| Percentile | Final Balance |
|---|---|
| 5th | $4,711 |
| 10th | $9,280 |
| 25th | $23,021 |
| 50th (Median) | $900,176 |
| 75th | $4,886,684 |
| 90th | $13,271,371 |
| 95th | $26,281,472 |

The direction flips from the 30-year case. Without the cushion, the success rate is *higher* at 60.6% — +1.3 percentage points. The median is also substantially higher: $900K vs $730K, a $170K difference. The lower tail, however, is essentially unchanged — $4,711 vs $5,073 at the 5th percentile, both effectively zero. The cushion isn't rescuing the failing scenarios; it's just costing the surviving ones.

## What We Found

The two retirement horizons produce opposite results, which turns out to tell a coherent story.

In the **30-year standard retirement** scenario, the cash cushion appears to win: the success rate is 1.2 percentage points higher, though at 1,000 simulations that gap is within noise. The more reliable signal is the lower tail: the 5th percentile is $104K with the cushion vs $39K without — a difference large enough to be meaningful. The cushion absorbs the bad early years before the portfolio has to sell at a loss, and that protection shows up where it matters most.

In the **50-year FIRE** scenario, being fully invested wins: +1.3 percentage points on success rate, and a $170K higher median. The lower tail is essentially identical either way — both near zero — because the failures in a 100% equity 50-year simulation are severe and early, and one year of cash cushion isn't nearly enough to change their outcome. What the cushion does do is cost the surviving scenarios compound growth on $40K over five decades, which is a significant drag.

The difference comes down to what kind of risk the cash cushion actually addresses. In the 30-year scenario with a 60/40 portfolio, the main threat is a bad first few years of retirement combined with forced selling — sequence-of-returns risk. The cushion directly targets that threat, and it works. In the 50-year 100% equity scenario, the failures tend to be total collapses from which no one-year buffer could recover. The cushion can't save those outcomes, but it reliably costs the outcomes that were going to survive anyway.

## Key Takeaways

1. **In standard retirement (30-year, 60/40), the cash cushion appears to improve outcomes.** The 1.2 percentage point success rate gap is within simulation noise, but the lower tail difference is hard to dismiss — the 5th percentile holds $104K with the cushion vs $39K without. The protection against sequence-of-returns risk in the critical early years is the main argument in the cushion's favour.
2. **In early retirement (50-year, 100% equity), the cash cushion hurts.** Success rate is 1.3 percentage points *lower*, and the median is $170K worse. The lower tail is the same either way — both near zero. The cushion doesn't rescue the failures; it just drags on the survivors.
3. **The cushion works when it can prevent failure; it doesn't when failure is already inevitable.** A bad first few years in a 30-year 60/40 portfolio is recoverable with the right buffer. A catastrophic 100% equity collapse over a 50-year horizon isn't — and one year of spending in cash makes no difference either way.
4. **The opportunity cost compounds over time.** $40K kept in a Canadian savings account at ~1% vs invested at 5% average is a meaningful difference over 30 years. Over 50 years with 100% equity, it's enormous — and the FIRE results show it.

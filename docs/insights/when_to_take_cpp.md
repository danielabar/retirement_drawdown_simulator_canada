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

We can run the simulation in "success rate" mode, which runs it over and over, calculating what percentage of runs result in success. Then we can modify the age at which CPP is taken to see how this affects the success rate.

## CPP at 60

Inputs are as follows:

```yml
mode: success_rate
total_runs: 1000
retirement_age: 60
max_age: 95
desired_spending: 40000
annual_tfsa_contribution: 0
province_code: ONT
success_factor: 1

return_sequence_type: geometric_brownian_motion
annual_growth_rate:
  average: 0.05
  min: -0.3
  max: 0.3
  downturn_threshold: -0.1
  savings: 0.005

accounts:
  rrsp: 600000
  taxable: 200000
  tfsa: 200000
  cash_cushion: 40000

cpp:
  start_age: 60
  monthly_amount: 896

taxes:
  rrsp_withholding_rate: 0.3
```

Run the program with `ruby main.rb`, and the output is:

```
Summary:
┌───────────────────────┬────────────┐
│ Description           │     Amount │
├───────────────────────┼────────────┤
│ Withdrawal Rate       │       4.0% │
│ Success Rate          │      93.0% │
│ Average Final Balance │ $2,578,949 │
└───────────────────────┴────────────┘

Final Balance Percentiles:
┌──────────────────────────┬────────────┐
│ Description              │     Amount │
├──────────────────────────┼────────────┤
│ 5th Percentile           │    $36,078 │
│ 10th Percentile          │   $193,513 │
│ 25th Percentile          │   $702,307 │
│ 50th Percentile (Median) │ $1,583,744 │
│ 75th Percentile          │ $3,355,852 │
│ 90th Percentile          │ $5,864,793 │
│ 95th Percentile          │ $8,024,417 │
└──────────────────────────┴────────────┘
```

The success rate of 93% might sound reassuring at first. If you got a 93% on a school exam, you’d probably feel pretty good about it. But retirement planning isn’t like a school test, where getting a few questions wrong just means losing a few points. In retirement, failure means running out of money while you’re still alive.

A better analogy is flying on an airplane. If an airline told you that a particular flight had a 93% chance of arriving safely, you probably wouldn’t board that plane! In the same way, a 93% success rate in retirement means that 7 out of 100 retirees in this situation will run out of money before reaching 95. That’s a big risk if you’re the one facing the shortfall.

### Interpreting the Final Balance Percentiles

While the **93% success rate** tells us the likelihood of not running out of money, the **Final Balance Percentiles** give us a sense of how much money might be left in different scenarios. This dispersion highlights the range of possible financial outcomes depending on how the market performs.

- The **5th percentile** (`$36,078`) shows a near-worst-case scenario—these retirees barely scrape by, finishing retirement with almost nothing left.
- The **10th percentile** (`$193,513`) is still quite low, meaning even in the bottom 10% of scenarios, people may come close to running out of money.
- The **25th percentile** (`$702,307`) suggests that a quarter of retirees end up with under $700K, which, while better, might still be concerning depending on spending needs.
- The **50th percentile (median) at `$1.58M`** represents the typical outcome—half of retirees end up with more than this, half with less.
- The **75th to 95th percentiles** show the upside potential, with some retirees accumulating several million dollars by the end of their lifespan.

### Key Takeaways

1. **Significant Variability:** There’s a **huge** spread between the worst and best-case outcomes. In some cases, people end up nearly broke, while in others, they finish retirement with over $8M. This highlights the uncertainty of investing and withdrawal planning.

2. **A Risk of Inefficiency:** If someone reaches 95 with $8M (the 95th percentile), it suggests they could have **spent more freely** during retirement. This raises a common challenge: balancing spending to avoid both running out of money and living too frugally.

3. **Impact of Market Performance:** The range of outcomes is largely driven by **market volatility**. Since the simulation uses a **Geometric Brownian Motion return model**, some runs experience strong market growth, while others hit downturns at unfortunate times. This reflects real-world investment risk.

4. **Why Guaranteed Income Matters:** A broad dispersion like this makes a strong case for securing guaranteed income sources like CPP. Since delaying CPP increases lifelong payments, it can help smooth out the worst-case scenarios and reduce reliance on volatile investments.

The goal of retirement planning isn’t just to maximize wealth but to minimize the risk of running out of money. That’s why strategies like delaying CPP, which increases guaranteed income for life, can be so valuable. Let's see how taking CPP later changes this probability.

## CPP at 65

We'll run the program again, with the only change being in the CPP, which we'll take at age 65. The remainder of the inputs are the same:

```yml
cpp:
  start_age: 65
  monthly_amount: 1524
```

Here are the results:

```
Summary:
┌───────────────────────┬────────────┐
│ Description           │     Amount │
├───────────────────────┼────────────┤
│ Withdrawal Rate       │       4.0% │
│ Success Rate          │      96.6% │
│ Average Final Balance │ $2,564,931 │
└───────────────────────┴────────────┘

Final Balance Percentiles:
┌──────────────────────────┬────────────┐
│ Description              │     Amount │
├──────────────────────────┼────────────┤
│ 5th Percentile           │    $87,337 │
│ 10th Percentile          │   $277,590 │
│ 25th Percentile          │   $824,848 │
│ 50th Percentile (Median) │ $1,817,265 │
│ 75th Percentile          │ $3,308,657 │
│ 90th Percentile          │ $5,635,425 │
│ 95th Percentile          │ $7,592,854 │
└──────────────────────────┴────────────┘
```

When CPP is delayed to **age 65**, the success rate increases from **93% to 96.6%**, meaning fewer retirees run out of money before **age 95**. While a **3.6% increase** might not seem huge, it represents a meaningful reduction in retirement failure risk.

The **Final Balance Percentiles** also shift favorably:

- The **5th percentile balance** increases from **`$36K` to `$87K`**, reducing the risk of running out of money.
- The **10th percentile balance** jumps from **`$193K` to `$277K`**, meaning even in poor market conditions, retirees have a better financial cushion.
- The **median final balance** increases from **`$1.58M` to `$1.82M`**, showing that in typical scenarios, delaying CPP leads to better long-term financial outcomes.
- The **95th percentile** remains high (`$7.6M` vs. `$8.0M`), showing that even though retirees spent the first few years withdrawing exclusively from their portfolio, this did not constrain the upside in strong market conditions.

### Why Does Delaying CPP Improve Success Rates?

1. **Higher Guaranteed Income** – With CPP increasing from **`$896` to `$1,524`/month**, retirees rely less on investment withdrawals, preserving portfolio longevity.
2. **Market Risk Reduction** – A higher baseline income means fewer withdrawals during downturns, reducing sequence-of-returns risk.
3. **Longevity Protection** – Since CPP payments last for life, retirees are less exposed to outliving their assets.

While the average final balance stays similar, delaying CPP **shifts more retirees away from failure scenarios**, making it a strong strategy for those concerned about running out of money.

## CPP at 70

Finally we run the program delaying CPP all the way to age 70:

```yml
cpp:
  start_age: 70
  monthly_amount: 2223
```

```
Summary:
┌───────────────────────┬────────────┐
│ Description           │     Amount │
├───────────────────────┼────────────┤
│ Withdrawal Rate       │       4.0% │
│ Success Rate          │      98.1% │
│ Average Final Balance │ $2,654,830 │
└───────────────────────┴────────────┘

Final Balance Percentiles:
┌──────────────────────────┬────────────┐
│ Description              │     Amount │
├──────────────────────────┼────────────┤
│ 5th Percentile           │   $213,424 │
│ 10th Percentile          │   $437,657 │
│ 25th Percentile          │   $971,247 │
│ 50th Percentile (Median) │ $1,832,769 │
│ 75th Percentile          │ $3,321,924 │
│ 90th Percentile          │ $5,373,945 │
│ 95th Percentile          │ $7,882,663 │
└──────────────────────────┴────────────┘
```

This time, delaying CPP **all the way to age 70** increases the success rate to **98.1%**, the highest so far. This means that almost every retiree in the simulation reaches age 95 without running out of money.

The **Final Balance Percentiles** show an even greater improvement:

- The **5th percentile balance** rises dramatically from **`$87K` (CPP at 65) to `$213K`**, meaning even in the worst 5% of cases, retirees maintain a much stronger financial cushion.
- The **10th percentile balance** more than **doubles** compared to CPP at 60, reaching **`$437K`**, significantly reducing the risk of financial shortfall.
- The **median final balance** remains similar to CPP at 65, around **`$1.83M`**, but with **fewer retirees falling into low-balance scenarios**.
- The **95th percentile balance** stays high at **`$7.88M`**, showing that delaying CPP does not limit the upside potential.

### Why Does Delaying CPP to 70 Improve Outcomes Even Further?

1. **Maximum Guaranteed Income** – At **`$2,223`/month**, CPP now replaces a larger portion of spending needs, significantly reducing pressure on investment withdrawals.
2. **Even Greater Market Risk Protection** – The need to sell investments in a downturn is further reduced, mitigating **sequence-of-returns risk**.
3. **Better Outcomes in the Worst Scenarios** – The biggest improvement is in the **low-percentile cases**—delaying CPP provides a substantial financial buffer for those who might otherwise struggle.

### The Bottom Line

Delaying CPP to 70 offers the **best protection against running out of money** while maintaining strong upside potential. The difference is most striking in poor market conditions, where retirees who delay are far better off. For those in good health, with a long retirement ahead, **delaying CPP is one of the most effective ways to improve financial security**.

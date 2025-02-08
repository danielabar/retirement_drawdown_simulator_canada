# Retirement Drawdown Simulator 🇨🇦

This is a simple, assumption-heavy retirement drawdown calculator for Canadians. It models a single drawdown strategy:

1. Withdraw from RRSP first (enough for spending + TFSA contribution).
2. Withdraw from Taxable account next (enough for spending + TFSA contribution).
3. Withdraw from TFSA last.

The idea being to drain the RRSP as quickly as possible to avoid mandatory RRIF withdrawals at age 71, with potential large tax liability.

It also models your first year of RRSP withdrawal and why you may need an additional cash buffer to cover some shortfall. See [first_year.md](first_year.md) for further details.

## Why I Built This

When I started looking for a basic tool to simulate a retirement drawdown in Canada, I couldn’t find anything — just advice to hire a financial planner. While professional guidance is valuable, a simple, transparent tool should exist for those who want to explore their numbers on their own.

Right now, the model is quite basic. It assumes constant returns, ignores RRIF minimums (because it attempts to drain the RRSP before mandatory withdrawals would kick in), CPP, and withdrawal fees or commissions — but these are all on my roadmap. This is just a starting point, and I hope to refine it over time. See [TODO.md](TODO.md) for more details.

If you’re looking for a flexible, multi-scenario, tax-optimized model, this isn't it. But if you want a straightforward way to see how long your savings might last under a very simple strategy, I hope this helps.

### Disclaimer ⚠️

This tool is for **informational and educational purposes only**. It does **not** constitute financial, tax, or investment advice. The calculations are based on **simplified assumptions** and **may not reflect your actual financial situation**. You should consult with a **qualified financial professional** before making any retirement, investment, or other financial decisions. Use this tool at your own risk.

## Getting Started

### Prerequisites

- Ruby version installed as per `.ruby-version`

### Installation

1. Clone the repository:

   ```sh
   git clone https://github.com/danielabar/retirement-simulator.git
   cd retirement-simulator
   ```

2. Install dependencies:

   ```sh
   bundle install
   ```

### Setup

1. Copy the template file:

   ```sh
   cp inputs.yml.template inputs.yml
   ```

2. Edit `inputs.yml` and enter your actual financial details.

   - The template file (`inputs.yml.template`) contains example values.
   - Open `inputs.yml` in a text editor and replace the values with your actual financial information.

### Running the Simulation

Run the script with:

```sh
ruby main.rb
```

The output will display a table showing account balances each year until depletion.

## Configuration

Your financial inputs are stored in `inputs.yml`. Below is an example:

```yaml
# Age at which you plan to start retirement
retirement_age: 60

# Max age to prevent infinite loops
max_age: 120

# Growth rate average, min, and max to generate variability
annual_growth_rate:
  average: 0.03
  min: -0.3
  max: 0.3

# Choose the return sequence generator: mean, geometric_brownian_motion, constant
return_sequence_type: mean

# Assume we'll continue to make TFSA contributions during RRSP and Taxable drawdown phases
annual_tfsa_contribution: 7000

# After tax amount, eg: variable + fixed + lumpy
desired_spending: 40000

# Have to withdraw more than desired_spending + tfsa contribution to account for taxes
# Add up your desired_spending and annual_tfsa_contribution, then figure out how much you'd actually need
# to withdraw to be left with desired_spending + annual_tfsa_contribution
# Use a tax calculator to figure this out: https://www.eytaxcalculators.com/en/2025-personal-tax-calculator.html
annual_withdrawal_amount_rrsp: 56000

# Starting account balances
accounts:
  rrsp: 600000
  taxable: 400000
  tfsa: 120000

# Taxes
# Withholding tax may be greater than your actual tax bill, you'll get a refund when you file your taxes.
# In the first year of retirement, you'll have to have some extra cash available to "float" the difference.
# In subsequent years, the previous year's tax refund will be used to fund part of next years spending.
# Tax calculator: https://www.eytaxcalculators.com/en/2025-personal-tax-calculator.html
# RRSP Withholding tax: https://www.canada.ca/en/revenue-agency/services/tax/individuals/topics/rrsps-related-plans/making-withdrawals/tax-rates-on-withdrawals.html
taxes:
  rrsp_withholding_rate: 0.3
  actual_tax_bill: 6360

# Investment details
# Unused - future capital gains tax determination
investment:
  market_price: 35.12
  cost_per_share: 29.34
```

## Sample Output

Running the program for the sample input with a bad initial sequence of returns:

```
=== First-Year Cash Flow Breakdown ===
Desired Income Including TFSA Contribution: $47,000.00
RRSP Withholding Tax: $16,800.00
Expected Tax Refund: $10,440.00
RRSP Available After Withholding: $39,200.00
Required Cash Buffer for First Year: $7,800.00
--------------------------------------------------------------------------------------------------------------
Age        RRSP                 TFSA                 Taxable              Note                        RoR
--------------------------------------------------------------------------------------------------------------
60         $572,362.18          $133,621.32          $420,854.54          RRSP Drawdown             5.21%
61         $368,585.30          $100,377.13          $300,410.85          RRSP Drawdown           -28.62%
62         $245,901.68          $84,470.43           $236,324.39          RRSP Drawdown           -21.33%
63         $246,087.97          $118,533.83          $306,245.80          RRSP Drawdown            29.59%
64         $157,377.35          $103,931.78          $253,546.56          RRSP Drawdown           -17.21%
65         $113,525.82          $124,225.20          $283,930.11          RRSP Drawdown            11.98%
66         $71,675.85           $163,503.57          $353,770.36          RRSP Drawdown             24.6%
67         $14,195.92           $154,406.64          $320,371.55          RRSP Drawdown            -9.44%
68         $18,326.58           $208,371.99          $352,915.93          Taxable Drawdown          29.1%
69         $14,693.99           $172,682.18          $245,279.01          Taxable Drawdown        -19.82%
70         $15,063.68           $184,202.85          $203,267.56          Taxable Drawdown          2.52%
71         $11,399.48           $144,693.23          $118,255.87          Taxable Drawdown        -24.32%
72         $10,203.63           $135,779.99          $63,780.83           Taxable Drawdown        -10.49%
73         $9,002.88            $125,977.82          $14,806.09           Taxable Drawdown        -11.77%
74         $7,522.57            $71,840.86           $12,371.59           TFSA Drawdown           -16.44%
75         $8,048.66            $34,067.66           $13,236.79           TFSA Drawdown             6.99%
```

### ⚠️ Important: Keep `inputs.yml` Private

Since `inputs.yml` contains personal financial information, it is **ignored by Git** (see `.gitignore`).
**Do not commit it** to avoid exposing sensitive data.

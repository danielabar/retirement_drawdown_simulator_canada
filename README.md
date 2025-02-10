# Retirement Drawdown Simulator 🇨🇦

This is a simple retirement drawdown calculator for Canadians. It models the following drawdown strategy:

1. Withdraw from RRSP first (enough for spending + optional TFSA contribution).
2. Withdraw from Taxable account next (enough for spending + optional TFSA contribution).
3. Withdraw from TFSA last.

The idea being to drain the RRSP as quickly as possible to avoid mandatory RRIF withdrawals at age 71, with potential large tax liability. Although there's a trade-off in needing to withdraw more earlier for additional TFSA contributions can increase your tax bracket. This application let's you try out different scenarios to see what works best for you.

It also models your first year of RRSP withdrawal and why you may need an additional cash buffer to cover some shortfall. See [First Year Shortfall](docs/first_year.md) for further details.

You can also run the same scenario over and over with different options for randomized returns, to see what your chances of success are.

## Why I Built This

When I started looking for a basic tool to simulate a retirement drawdown in Canada, I couldn’t find anything — just advice to hire a financial planner. While professional guidance is valuable, a simple, transparent tool should exist for those who want to see how long their savings might last under a simple strategy. But something that considered initial withdrawals from an RRSP have to be higher than desired spending to account for taxes. Because RRSP withdrawals count as income and are subject to federal and provincial income tax.

Specifically, this tool could be useful for someone who has three accounts from which they wish to drawdown in retirement: an RRSP, taxable account, and TFSA. It assumes the same investments are held in all of them so the same rate of return can be applied.

There are many assumptions and some things such as RRIF withdrawals, capital gains, and CPP are not handled, although planned. See the [roadmap](docs/roadmap.md) for more details.

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

The output will display a table showing account balances each year until depletion, and whether your plan was successful or failed.

Or to run the simulation multiple times to see what percentage of scenarios are successful, run:

```sh
ruby main.rb success_rate
```

## Configuration

Your financial inputs are stored in `inputs.yml`. Below is an example:

```yaml
# Mode can be 'detailed' for a single run with detailed output, or 'success_rate'
mode: detailed

# For success_rate mode
total_runs: 5000

# Age at which you plan to start retirement
retirement_age: 60

# Max age to prevent infinite loops
max_age: 105

# Success factor: defines the multiplier for total_balance needed by max_age for success.
# Supports fractional, eg: 1.5
success_factor: 1

# Growth rate average, min, and max to generate variability
# Enter the "real" return rather than nominal as inflation isn't handled currently.
# For example if you're invested in broad market index funds or ETF's and using
# an average return of 8%, but inflation is around 3%, then put 5% real return here.
# The min and max are to constrain volatility. For example the market has dropped
# by 30% and has grown by that much as well.
annual_growth_rate:
  average: 0.05
  min: -0.3
  max: 0.3

# Choose the return sequence generator: mean, geometric_brownian_motion, constant
# If using `success_rate` mode, then choose either `mean` or `geometric_brownian_motion`
# `constant` returns are conceptually easy to understand, and produce pleasing predictable results,
# but are unrealistic as the market doesn't actually do this.
return_sequence_type: geometric_brownian_motion

# Assume we'll continue to make TFSA contributions during RRSP and Taxable drawdown phases
# If you don't want to do this, set to 0
annual_tfsa_contribution: 7000

# After tax amount you need per year in retirement (NOT including TFSA contribution, this is your spending number).
# To get an accurate number here, you should track your spending for at least a year
# Or review a year's worth of past credit card statements and other sources of spending.
# Add up:
#   1. Variable spending (groceries, personal, entertainment, travel, etc.)
#   2. Fixed spending (any constant recurring payments)
#   3. Lumpy (eg: new car, replace roof, new appliances, computer, etc. only happen every few years so divide amount by how many years expense occurs)
desired_spending: 40000

# Have to withdraw more than desired_spending + tfsa contribution to account for taxes.
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
# Assumption is you'll be withdrawing at least 15K which lands in 30% withholding tax.
taxes:
  rrsp_withholding_rate: 0.3
  actual_tax_bill: 6360
```

## Sample Output

Here's a run using `inputs.yml` copied from `inputs.yml.template` with a successful result - i.e. money lasts up until `max_age` of 105, with more than 1x desired_income left.
```
ruby main.rb

=== First-Year Cash Flow Breakdown ===
Desired Income Including TFSA Contribution: $47,000.00
RRSP Withholding Tax: $16,800.00
Expected Tax Refund: $10,440.00
RRSP Available After Withholding: $39,200.00
Required Cash Buffer for First Year: $7,800.00
----------------------------------------------------------------------------------------------------------------------------------
Age        RRSP                 TFSA                 Taxable              Total Balance        Note                        RoR
----------------------------------------------------------------------------------------------------------------------------------
60         $552,323.56          $128,943.19          $406,120.27          $1,087,387.02        RRSP Drawdown             1.53%
61         $531,298.71          $145,522.89          $434,738.93          $1,111,560.53        RRSP Drawdown             7.05%
62         $538,432.81          $172,782.56          $492,485.46          $1,203,700.83        RRSP Drawdown            13.28%
63         $482,311.31          $179,737.28          $492,361.43          $1,154,410.02        RRSP Drawdown            -0.03%
64         $418,483.32          $183,308.38          $483,320.61          $1,085,112.31        RRSP Drawdown            -1.84%
65         $410,596.72          $215,568.54          $547,473.08          $1,173,638.33        RRSP Drawdown            13.27%
66         $381,535.78          $239,477.29          $589,065.15          $1,210,078.22        RRSP Drawdown              7.6%
67         $348,287.15          $263,703.34          $630,234.32          $1,242,224.80        RRSP Drawdown             6.99%
68         $305,492.45          $282,933.50          $658,707.80          $1,247,133.75        RRSP Drawdown             4.52%
69         $288,124.82          $334,827.91          $760,704.65          $1,383,657.38        RRSP Drawdown            15.48%
70         $211,421.40          $311,339.97          $692,856.71          $1,215,618.07        RRSP Drawdown            -8.92%
71         $179,695.49          $368,059.09          $801,068.78          $1,348,823.36        RRSP Drawdown            15.62%
72         $128,380.85          $389,265.63          $831,411.77          $1,349,058.25        RRSP Drawdown             3.79%
73         $74,810.72           $409,568.52          $859,322.79          $1,343,702.03        RRSP Drawdown             3.36%
74         $18,512.91           $409,973.58          $845,718.35          $1,274,204.84        RRSP Drawdown            -1.58%
75         $16,736.25           $376,957.11          $722,066.27          $1,115,759.63        Taxable Drawdown          -9.6%
76         $16,013.28           $367,370.98          $645,904.85          $1,029,289.12        Taxable Drawdown         -4.32%
77         $18,649.68           $436,006.68          $697,507.36          $1,152,163.72        Taxable Drawdown         16.46%
78         $17,583.58           $417,682.51          $613,321.56          $1,048,587.65        Taxable Drawdown         -5.72%
79         $17,685.05           $427,133.31          $569,589.74          $1,014,408.11        Taxable Drawdown          0.58%
80         $18,086.98           $443,999.80          $534,466.57          $996,553.35          Taxable Drawdown          2.27%
81         $17,879.22           $445,819.22          $481,867.10          $945,565.53          Taxable Drawdown         -1.15%
82         $16,033.98           $406,085.79          $389,986.43          $812,106.20          Taxable Drawdown        -10.32%
83         $18,806.52           $484,514.98          $402,294.31          $905,615.82          Taxable Drawdown         17.29%
84         $19,791.29           $517,252.29          $373,898.67          $910,942.25          Taxable Drawdown          5.24%
85         $17,359.11           $459,826.16          $286,725.61          $763,910.88          Taxable Drawdown        -12.29%
86         $19,100.99           $513,669.27          $263,780.59          $796,550.85          Taxable Drawdown         10.03%
87         $16,566.89           $451,592.88          $188,020.65          $656,180.42          Taxable Drawdown        -13.27%
88         $17,311.01           $479,191.22          $147,354.78          $643,857.02          Taxable Drawdown          4.49%
89         $15,071.86           $423,303.08          $87,374.04           $525,748.97          Taxable Drawdown        -12.93%
90         $17,934.04           $512,018.67          $48,041.16           $577,993.88          Taxable Drawdown         18.99%
91         $20,016.02           $579,271.94          $1,162.03            $600,449.99          Taxable Drawdown         11.61%
92         $19,756.83           $532,288.86          $1,146.98            $553,192.67          TFSA Drawdown            -1.29%
93         $19,949.96           $497,101.15          $1,158.20            $518,209.31          TFSA Drawdown             0.98%
94         $22,799.72           $522,396.00          $1,323.64            $546,519.36          TFSA Drawdown            14.28%
95         $22,729.34           $480,906.83          $1,319.55            $504,955.72          TFSA Drawdown            -0.31%
96         $22,501.80           $436,493.06          $1,306.34            $460,301.20          TFSA Drawdown             -1.0%
97         $27,428.66           $483,306.82          $1,592.37            $512,327.85          TFSA Drawdown             21.9%
98         $25,848.97           $417,775.60          $1,500.66            $445,125.24          TFSA Drawdown            -5.76%
99         $27,182.81           $397,269.37          $1,578.10            $426,030.28          TFSA Drawdown             5.16%
100        $26,003.10           $341,764.09          $1,509.61            $369,276.80          TFSA Drawdown            -4.34%
101        $24,839.21           $288,257.25          $1,442.04            $314,538.50          TFSA Drawdown            -4.48%
102        $27,947.49           $279,323.16          $1,622.49            $308,893.14          TFSA Drawdown            12.51%
103        $26,135.11           $223,803.25          $1,517.28            $251,455.64          TFSA Drawdown            -6.48%
104        $20,957.00           $147,386.57          $1,216.66            $169,560.23          TFSA Drawdown           -19.81%
105        $20,957.00           $147,386.57          $1,216.66            $169,560.23          Exited TFSA Drawdown due to reaching max age      9.79%
----------------------------------------------------------------------------------------------------------------------------------
Simulation Result: Success
Simulation successful with total balance of $169,560.23.
```

Here's another run where a bad initial sequence of returns causes the money to run out by age 76:
```
ruby main.rb

=== First-Year Cash Flow Breakdown ===
Desired Income Including TFSA Contribution: $47,000.00
RRSP Withholding Tax: $16,800.00
Expected Tax Refund: $10,440.00
RRSP Available After Withholding: $39,200.00
Required Cash Buffer for First Year: $7,800.00
----------------------------------------------------------------------------------------------------------------------------------
Age        RRSP                 TFSA                 Taxable              Total Balance        Note                        RoR
----------------------------------------------------------------------------------------------------------------------------------
60         $522,986.13          $122,094.19          $384,548.62          $1,029,628.94        RRSP Drawdown            -3.86%
61         $463,458.99          $128,119.14          $381,644.14          $973,222.27          RRSP Drawdown            -0.76%
62         $394,557.67          $130,840.88          $369,560.19          $894,958.74          RRSP Drawdown            -3.17%
63         $313,339.43          $127,573.49          $342,032.65          $782,945.56          RRSP Drawdown            -7.45%
64         $257,685.84          $134,754.64          $342,493.07          $734,933.55          RRSP Drawdown             0.13%
65         $211,868.17          $148,911.28          $359,784.21          $720,563.66          RRSP Drawdown             5.05%
66         $140,704.97          $140,743.89          $324,783.61          $606,232.46          RRSP Drawdown            -9.73%
67         $91,371.31           $159,371.43          $350,344.29          $601,087.02          RRSP Drawdown             7.87%
68         $41,960.42           $197,363.80          $415,607.89          $654,932.11          RRSP Drawdown            18.63%
69         $36,947.34           $179,948.11          $324,569.70          $541,465.15          Taxable Drawdown        -11.95%
70         $38,262.32           $193,601.70          $287,448.55          $519,312.57          Taxable Drawdown          3.56%
71         $37,878.19           $198,587.79          $238,034.61          $474,500.60          Taxable Drawdown          -1.0%
72         $30,560.53           $165,870.47          $154,128.80          $350,559.81          Taxable Drawdown        -19.32%
73         $23,410.39           $132,424.57          $82,064.25           $237,899.22          Taxable Drawdown         -23.4%
74         $19,670.53           $117,151.19          $29,462.66           $166,284.39          Taxable Drawdown        -15.98%
75         $19,464.05           $76,341.33           $29,153.39           $124,958.77          TFSA Drawdown            -1.05%
76         $16,498.65           $30,804.63           $24,711.79           $72,015.07           TFSA Drawdown           -15.24%
----------------------------------------------------------------------------------------------------------------------------------
Simulation Result: Failure
Simulation failed. Max age 105 not reached. Final age is 76.
```

You can use the `success_rate` mode (either specify it in `inputs.yml` or override it at the command line as shown below) to run the simulation 5000 times (or however many times you specify in `total_runs`). In this case, it calculates the percentage of successful scenarios:

```
ruby main.rb success_rate

Simulating... [████████████████████████████████████████] 100%

Simulation Success Rate: 66.74%
```

Success is defined as making it to `max_age` with at least `success_factor` * annual withdrawals in that phase, money left.

For example, suppose `max_age` is `105`, `desired_spending` is `40000` and success_factor is `1.5`. Then if the scenario shows that there's still 40000 * 1.5 = `$60,000` left by age `105`, this is considered a success.

> [!NOTE]
> The 4% rule research considers reaching the end of life with even just `$1.00` a "success". Realistically, most people would be freaking out if they were getting on in their 90's and their account balance was dwindling down like that.

### ⚠️ Important: Keep `inputs.yml` Private

Since `inputs.yml` contains personal financial information, it is **ignored by Git** (see `.gitignore`).
**Do not commit it** to avoid exposing sensitive data.

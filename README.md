# Retirement Drawdown Simulator 🇨🇦

This is a simple retirement drawdown calculator for Canadians. It models the following drawdown strategy:

1. Withdraw from RRSP first (enough for spending + optional TFSA contribution).
2. Withdraw from Taxable account next (enough for spending + optional TFSA contribution).
3. Withdraw from TFSA last.
4. Optionally if you specify a cash cushion (i.e. amount of savings you have in an easily accessible liquid account like a high interest savings account), then the simulation will drawdown from the cash cushion rather than investment accounts during periods of market downturns.

> [!IMPORTANT]
> RRSP withdrawals are treated as income and subject to federal and provincial income tax. This project does a reverse tax calculation, to determine what amount you actually need to withdraw from RRSP to achieve desired spending (and optional TFSA contribution) amount. This is often overlooked in FIRE/retirement calculators.

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
total_runs: 500

# Age at which you plan to start retirement
retirement_age: 60

# Maximum age to run the simulation until.
# This prevents infinite loops if investment growth outpaces withdrawals.
# Choose a reasonable upper bound based on longevity estimates,
# but note that this is just for the simulation and not a personal prediction.
max_age: 105

# Province or territory where you reside
# Valid values are: ONT, NL, PE, NS, NB, MB, SK, AB, BC, YT, NT, NU
province_code: ONT

# Success factor: defines the multiplier for total_balance needed by max_age for success.
# Supports fractional, eg: 1.5
success_factor: 1

# Growth rate average, min, and max to generate variability
# Enter the "real" return rather than nominal as inflation isn't handled currently.
# For example if you're invested in broad market index funds or ETF's and using
# an average return of 8%, but inflation is around 3%, then put 5% real return here.
# The min and max are to constrain volatility. For example the market has dropped
# by 30% and has grown by that much as well.
# Set a downturn_threshold so if market return is below this amount, use cash_cushion.
annual_growth_rate:
  average: 0.05
  min: -0.3
  max: 0.3
  downturn_threshold: -0.2

# Choose the return sequence generator: mean, geometric_brownian_motion, constant
# If using `success_rate` mode, then choose either `mean` or `geometric_brownian_motion`
# `constant` returns are conceptually easy to understand, and produce pleasing predictable results,
# but are unrealistic as the market doesn't actually do this.
return_sequence_type: geometric_brownian_motion

# Optionally continue to make TFSA contributions during RRSP and Taxable drawdown phases
# If you don't want to make any TFSA contributions during drawdown, set this to 0.
annual_tfsa_contribution: 7000

# After tax amount you need per year in retirement (NOT including TFSA contribution, this is your spending number).
# To get an accurate number here, you should track your spending for at least a year
# Or review a year's worth of past credit card statements and other sources of spending.
# Add up:
#   1. Variable spending (groceries, personal, entertainment, travel, etc.)
#   2. Fixed spending (any constant recurring payments)
#   3. Lumpy (eg: new car, replace roof, replace appliances etc. only happen every few years so divide amount by how many years expense occurs)
desired_spending: 40000

# Starting account balances.
# The cash_cushion will be used in case of market downturns (value you set earlier in downturn_threshold).
# Set cash_cushion balance to 0 if you don't want to use it or don't have a cash cushion.
accounts:
  rrsp: 600000
  taxable: 400000
  tfsa: 120000
  cash_cushion: 40000

# Enter the age at which you plan to start CPP and the monthly amount you're entitled to.
# You can find this value by logging in to your My Service Canada account.
# The values shown in My Service Canada assume you continue to work at your current income
# up until the age you start taking CPP. If you're planning on retiring earlier than this,
# then your actual CPP numbers will be lower due to those additional years of no contributions.
# In this case, use https://research-tools.pwlcapital.com/research/cpp to estimate what you may actually get.
# To run the simulation without CPP, set the monthly_amount to 0.
cpp:
  start_age: 65
  monthly_amount: 0

# Taxes
# Withholding tax may be greater than your actual tax bill, you'll get a refund when you file your taxes.
# In the first year of retirement, you'll have to have some extra cash available to "float" the difference.
# In subsequent years, the previous year's tax refund will be used to fund part of next years spending.
# Tax calculator: https://www.eytaxcalculators.com/en/2025-personal-tax-calculator.html
# RRSP Withholding tax: https://www.canada.ca/en/revenue-agency/services/tax/individuals/topics/rrsps-related-plans/making-withdrawals/tax-rates-on-withdrawals.html
# Assumption is you'll be withdrawing at least 15K which lands in 30% withholding tax.
taxes:
  rrsp_withholding_rate: 0.3
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
60         $535,622.03          $125,044.11          $393,839.73          $1,054,505.87        rrsp                     -1.54%
61         $732,539.78          $201,674.57          $601,522.13          $1,535,736.48        rrsp                     52.73%
62         $782,960.14          $241,499.28          $696,142.15          $1,720,601.57        rrsp                     15.73%
63         $657,247.50          $224,669.17          $629,384.83          $1,511,301.49        rrsp                     -9.59%
64         $633,713.43          $244,178.75          $663,370.11          $1,541,262.30        rrsp                       5.4%
65         $560,697.28          $243,780.45          $643,831.00          $1,448,308.74        rrsp                     -2.95%
66         $520,633.16          $258,698.88          $664,160.04          $1,443,492.08        rrsp                      3.16%
67         $496,542.43          $283,946.09          $709,772.09          $1,490,260.61        rrsp                      6.87%
68         $478,739.54          $316,172.48          $771,312.66          $1,566,224.68        rrsp                      8.67%
69         $431,850.74          $330,137.74          $787,936.58          $1,549,925.06        rrsp                      2.16%
70         $392,404.01          $351,986.01          $822,639.00          $1,567,029.02        rrsp                       4.4%
71         $441,395.79          $471,025.64          $1,079,384.84        $1,991,806.27        rrsp                     31.21%
72         $353,699.29          $438,710.88          $990,611.89          $1,783,022.06        rrsp                     -8.22%
73         $322,972.19          $483,549.10          $1,074,708.97        $1,881,230.26        rrsp                      8.49%
74         $258,714.85          $475,376.61          $1,041,468.65        $1,775,560.12        rrsp                     -3.09%
75         $199,392.21          $474,470.12          $1,024,398.24        $1,698,260.57        rrsp                     -1.64%
76         $142,808.83          $479,511.30          $1,020,230.57        $1,642,550.71        rrsp                     -0.41%
77         $85,593.50           $479,700.09          $1,005,947.24        $1,571,240.83        rrsp                      -1.4%
78         $35,527.02           $584,283.88          $1,207,640.53        $1,827,451.44        rrsp                     20.05%
79         $40,459.87           $673,382.37          $1,321,792.96        $2,035,635.20        taxable                  13.88%
80         $49,453.73           $831,625.13          $1,558,167.75        $2,439,246.62        taxable                  22.23%
81         $51,963.01           $881,176.88          $1,587,844.24        $2,520,984.14        taxable                   5.07%
82         $50,673.74           $866,139.99          $1,502,613.78        $2,419,427.51        taxable                  -2.48%
83         $40,958.66           $705,743.15          $1,176,546.10        $1,923,247.91        taxable                 -19.17%
84         $52,916.92           $920,835.17          $1,459,327.62        $2,433,079.71        taxable                   29.2%
85         $52,500.41           $920,532.15          $1,401,211.15        $2,374,243.70        taxable                  -0.79%
86         $53,693.07           $948,603.01          $1,384,974.93        $2,387,271.00        taxable                   2.27%
87         $55,754.63           $992,293.66          $1,389,346.87        $2,437,395.16        taxable                   3.84%
88         $56,148.99           $1,006,361.84        $1,351,841.52        $2,414,352.36        taxable                   0.71%
89         $141.30              $961,045.00          $1,282,049.99        $2,243,236.29        rrsp                     -5.16%
90         $162.91              $1,116,080.71        $1,423,916.72        $2,540,160.33        taxable                  15.29%
91         $165.21              $1,138,948.00        $1,396,370.30        $2,535,483.51        taxable                   1.41%
92         $164.65              $1,142,086.64        $1,344,823.49        $2,487,074.78        taxable                  -0.34%
93         $145.62              $1,016,277.80        $1,147,823.98        $2,164,247.41        taxable                 -11.56%
94         $146.88              $1,032,085.69        $1,110,299.35        $2,142,531.91        taxable                   0.86%
95         $144.84              $1,024,680.25        $1,048,558.22        $2,073,383.31        taxable                  -1.39%
96         $167.86              $1,195,612.02        $1,160,703.67        $2,356,483.55        taxable                  15.89%
97         $163.10              $1,168,531.62        $1,082,142.81        $2,250,837.53        taxable                  -2.83%
98         $163.46              $1,178,169.63        $1,037,465.78        $2,215,798.88        taxable                   0.22%
99         $176.76              $1,281,587.08        $1,071,043.42        $2,352,807.26        taxable                   8.14%
100        $183.62              $1,338,608.38        $1,063,795.48        $2,402,587.48        taxable                   3.88%
101        $225.18              $1,650,098.13        $1,246,880.11        $2,897,203.42        taxable                  22.63%
102        $234.18              $1,723,338.41        $1,247,843.71        $2,971,416.30        taxable                    4.0%
103        $265.62              $1,962,633.44        $1,362,054.97        $3,324,954.02        taxable                  13.42%
104        $265.63              $1,969,735.28        $1,315,122.96        $3,285,123.86        taxable                   0.01%
105        $225.06              $1,674,849.39        $1,074,455.94        $2,749,530.39        taxable                 -15.27%
----------------------------------------------------------------------------------------------------------------------------------
Simulation Result: ✅ Success
Simulation successful with total balance of $2,749,530.39.
```

Here's another run where a bad initial sequence of returns causes the money to run out by age 83:
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
60         $511,317.37          $119,370.05          $375,968.66          $1,006,656.08        rrsp                     -6.01%
61         $463,932.41          $128,761.09          $383,082.34          $975,775.83          rrsp                      1.89%
62         $373,177.50          $124,194.56          $350,444.60          $847,816.66          rrsp                     -8.52%
63         $338,307.56          $139,934.61          $373,790.88          $852,033.05          rrsp                      6.66%
64         $271,769.64          $141,449.86          $359,838.09          $773,057.60          rrsp                     -3.73%
65         $250,937.12          $172,645.14          $418,486.74          $842,069.00          rrsp                      16.3%
66         $159,736.00          $147,205.41          $342,917.76          $649,859.16          rrsp                    -18.06%
67         $111,937.63          $166,397.27          $370,029.69          $648,364.59          rrsp                      7.91%
68         $57,751.26           $179,019.22          $382,026.93          $618,797.41          rrsp                      3.24%
69         $1,774.78            $188,517.68          $387,158.00          $577,450.45          rrsp                      1.34%
70         $1,898.33            $209,128.45          $363,837.77          $574,864.55          taxable                   6.96%
71         $1,712.40            $194,959.35          $285,804.51          $482,476.26          taxable                  -9.79%
72         $1,905.96            $224,788.74          $265,798.86          $492,493.56          taxable                   11.3%
73         $1,609.84            $195,776.44          $184,804.76          $382,191.04          taxable                 -15.54%
74         $1,772.80            $223,303.25          $151,754.56          $376,830.61          taxable                  10.12%
75         $1,691.30            $219,714.83          $99,938.37           $321,344.50          taxable                   -4.6%
76         $1,625.15            $217,847.51          $50,867.83           $270,340.49          taxable                  -3.91%
77         $1,630.68            $225,612.93          $3,881.00            $231,124.60          taxable                   0.34%
78         $1,761.29            $200,480.33          $4,191.86            $206,433.49          tfsa                      8.01%
79         $1,724.06            $157,087.49          $4,103.24            $162,914.78          tfsa                     -2.11%
80         $1,908.35            $129,603.66          $4,541.86            $136,053.87          tfsa                     10.69%
81         $2,015.17            $94,619.33           $4,796.09            $101,430.59          tfsa                       5.6%
82         $2,839.04            $76,949.38           $6,756.88            $86,545.30           tfsa                     40.88%
83         $2,764.35            $35,977.30           $6,579.12            $45,320.77           tfsa                     -2.63%
----------------------------------------------------------------------------------------------------------------------------------
Simulation Result: ❌ Failure
Simulation failed. Max age 105 not reached. Final age is 83.
```

### Determining Your Success Rate

You can use the `success_rate` mode (either specify it in `inputs.yml` or override it at the command line as shown below) to run the simulation many times over. In this case, it calculates the percentage of successful scenarios:

```
ruby main.rb success_rate

Running main.rb in success_rate mode...
Simulating... [████████████████████████████████████████] 100%

Simulation Success Rate: 69.26%
```

Success is defined as making it to `max_age` with at least `success_factor` * annual withdrawals in that phase, money left.

For example, suppose `max_age` is `105`, `desired_spending` is `40000` and success_factor is `1.5`. Then if the scenario shows that there's still 40000 * 1.5 = `$60,000` left by age `105`, this is considered a success.

> [!NOTE]
> The 4% rule research considers reaching the end of life with even just `$1.00` a "success". Realistically, most people would be freaking out if they were getting on in their 90's and their account balance was dwindling down like that.

### ⚠️ Important: Keep `inputs.yml` Private

Since `inputs.yml` contains personal financial information, it is **ignored by Git** (see `.gitignore`).
**Do not commit it** to avoid exposing sensitive data.

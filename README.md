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

# Conservative because all calculations are in today's dollars
annual_growth_rate: 0.03

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

Running the program for the sample input:

```
=== First-Year Cash Flow Breakdown ===
Desired Income Including TFSA Contribution: $47,000.00
RRSP Withholding Tax: $16,800.00
Expected Tax Refund: $10,440.00
RRSP Available After Withholding: $39,200.00
Required Cash Buffer for First Year: $7,800.00
------------------------------------------------------------------------------------------
Age        RRSP                 TFSA                 Taxable              Note
------------------------------------------------------------------------------------------
60         $560,320.00          $130,810.00          $412,000.00          RRSP Drawdown
61         $519,449.60          $141,944.30          $424,360.00          RRSP Drawdown
62         $477,353.09          $153,412.63          $437,090.80          RRSP Drawdown
63         $433,993.68          $165,225.01          $450,203.52          RRSP Drawdown
64         $389,333.49          $177,391.76          $463,709.63          RRSP Drawdown
65         $343,333.50          $189,923.51          $477,620.92          RRSP Drawdown
66         $295,953.50          $202,831.22          $491,949.55          RRSP Drawdown
67         $247,152.11          $216,126.15          $506,708.03          RRSP Drawdown
68         $196,886.67          $229,819.94          $521,909.27          RRSP Drawdown
69         $145,113.27          $243,924.54          $537,566.55          RRSP Drawdown
70         $91,786.67           $258,452.27          $553,693.55          RRSP Drawdown
71         $36,860.27           $273,415.84          $570,304.35          RRSP Drawdown
72         $37,966.08           $288,828.31          $539,003.49          Taxable Drawdown
73         $39,105.06           $304,703.16          $506,763.59          Taxable Drawdown
74         $40,278.21           $321,054.26          $473,556.50          Taxable Drawdown
75         $41,486.56           $337,895.89          $439,353.19          Taxable Drawdown
76         $42,731.15           $355,242.76          $404,123.79          Taxable Drawdown
77         $44,013.09           $373,110.05          $367,837.50          Taxable Drawdown
78         $45,333.48           $391,513.35          $330,462.63          Taxable Drawdown
79         $46,693.48           $410,468.75          $291,966.51          Taxable Drawdown
80         $48,094.29           $429,992.81          $252,315.50          Taxable Drawdown
81         $49,537.12           $450,102.59          $211,474.97          Taxable Drawdown
82         $51,023.23           $470,815.67          $169,409.22          Taxable Drawdown
83         $52,553.93           $492,150.14          $126,081.49          Taxable Drawdown
84         $54,130.54           $514,124.65          $81,453.94           Taxable Drawdown
85         $55,754.46           $536,758.39          $35,487.55           Taxable Drawdown
86         $57,427.09           $511,661.14          $36,552.18           TFSA Drawdown
87         $59,149.91           $485,810.97          $37,648.75           TFSA Drawdown
88         $60,924.41           $459,185.30          $38,778.21           TFSA Drawdown
89         $62,752.14           $431,760.86          $39,941.56           TFSA Drawdown
90         $64,634.70           $403,513.69          $41,139.80           TFSA Drawdown
91         $66,573.74           $374,419.10          $42,374.00           TFSA Drawdown
92         $68,570.95           $344,451.67          $43,645.22           TFSA Drawdown
93         $70,628.08           $313,585.22          $44,954.57           TFSA Drawdown
94         $72,746.93           $281,792.78          $46,303.21           TFSA Drawdown
95         $74,929.33           $249,046.56          $47,692.31           TFSA Drawdown
96         $77,177.21           $215,317.96          $49,123.07           TFSA Drawdown
97         $79,492.53           $180,577.50          $50,596.77           TFSA Drawdown
98         $81,877.31           $144,794.82          $52,114.67           TFSA Drawdown
99         $84,333.63           $107,938.67          $53,678.11           TFSA Drawdown
100        $86,863.63           $69,976.82           $55,288.45           TFSA Drawdown
101        $89,469.54           $30,876.13           $56,947.11           TFSA Drawdown
```

### ⚠️ Important: Keep `inputs.yml` Private

Since `inputs.yml` contains personal financial information, it is **ignored by Git** (see `.gitignore`).
**Do not commit it** to avoid exposing sensitive data.

## Contributing

If you'd like to contribute:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature-name`)
3. Commit your changes (`git commit -m "Add feature"`)
4. Please include tests
5. Run `bin/ci` to verify all is well
6. Push to the branch (`git push origin feature-name`)
7. Open a Pull Request

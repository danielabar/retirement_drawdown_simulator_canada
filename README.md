# Retirement Drawdown Simulator 🇨🇦

This is a simple, assumption-heavy retirement drawdown calculator for Canadians. It models a single drawdown strategy:

1. Withdraw from RRSP first (enough for spending + TFSA contribution).
2. Withdraw from Taxable account next (enough for spending + TFSA contribution).
3. Withdraw from TFSA last.

## Why I Built This

When I started looking for a basic tool to simulate a retirement drawdown in Canada, I couldn’t find anything — just advice to hire a financial planner. While professional guidance is valuable, a simple, transparent tool should exist for those who want to explore their numbers on their own.

Right now, the model is quite basic. It assumes constant returns, ignores RRIF minimums (because it attempts to drain the RRSP before mandatory withdrawals would kick in), CPP, and withdrawal fees or commissions — but these are all on my roadmap. This is just a starting point, and I hope to refine it over time.

If you’re looking for a flexible, tax-optimized model, this isn't it. But if you want a straightforward way to see how long your savings might last under a simple strategy, I hope this helps.

## Getting Started

### Prerequisites

- Ruby version installed as per `.ruby-version`

### Installation

1. Clone the repository:

   ```sh
   git clone https://github.com/danielabar/retirement-simulator.git
   cd retirement-simulator
   ```

2. Install dependencies (if any):

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
# Retirement assumptions
retirement_age: 60

# Conservative because all calcs remain in todays dollars
annual_growth_rate: 0.025

# Assume we'll continue to make TFSA contributions during
# RRSP and Taxable drawdown phases
annual_tfsa_contribution: 7000

# After tax amount, eg: variable + fixed + lumpy
desired_spending: 40000

# Have to withdraw more than desired_spending to account for taxes
# Use a tax calculator to figure this out: https://www.eytaxcalculators.com/en/2025-personal-tax-calculator.html
annual_withdrawal_amount_rrsp: 47000

# Account balances
accounts:
  rrsp: 500000
  taxable: 400000
  tfsa: 100000

# Tax assumptions
# Tax calculator: https://www.eytaxcalculators.com/en/2025-personal-tax-calculator.html
# RRSP Withholding tax: https://www.canada.ca/en/revenue-agency/services/tax/individuals/topics/rrsps-related-plans/making-withdrawals/tax-rates-on-withdrawals.html
# Note: Withholding tax may be greater than your actual tax bill, you'll get a refund when you file your taxes.
# But in the first year of retirement, you'll have to have some extra cash available to "float" the difference.
taxes:
  rrsp_withholding_rate: 0.3
  actual_tax_bill: 6360
```

### ⚠️ Important: Keep `inputs.yml` Private

Since `inputs.yml` contains personal financial information, it is **ignored by Git** (see `.gitignore`).
**Do not commit it** to avoid exposing sensitive data.

## Contributing

If you'd like to contribute:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature-name`)
3. Commit your changes (`git commit -m "Add feature"`)
4. Push to the branch (`git push origin feature-name`)
5. Open a Pull Request

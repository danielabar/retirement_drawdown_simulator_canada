require_relative 'retirement_plan'

class Simulator
  def initialize(plan)
    @plan = plan
    @age = plan.retirement_age
    @rrsp_balance = plan.rrsp_balance
    @taxable_balance = plan.taxable_balance
    @tfsa_balance = plan.tfsa_balance
  end

  def run
    print_summary
    print_header
    simulate_rrsp_drawdown
    simulate_taxable_drawdown
    simulate_tfsa_drawdown
  end

  private

  def print_header
    puts format("%-10s %-20s %-20s %-20s %-20s",
                "Age",
                "RRSP",
                "TFSA",
                "Taxable",
                "Note")
    puts "-" * 90
  end

  def print_summary
    puts "Desired Income: #{format_currency(@plan.desired_income)}"
    puts "RRSP Withholding Tax: #{format_currency(@plan.tax_withholding)}"
    puts "Expected Refund: #{format_currency(@plan.expected_refund)}"
    puts "RRSP Available After Tax: #{format_currency(@plan.rrsp_withdrawal_actual_amount_available)}"
    puts "Amount Available in Subsequent Years: #{format_currency(@plan.amount_available_subsequent_years)}"
    puts "-" * 90
  end

  def simulate_rrsp_drawdown
    while @rrsp_balance >= @plan.annual_withdrawal_amount_rrsp
      @rrsp_balance -= @plan.annual_withdrawal_amount_rrsp
      @tfsa_balance += @plan.annual_tfsa_contribution
      apply_growth
      print_yearly_status("RRSP Drawdown")
      @age += 1
    end
  end

  def simulate_taxable_drawdown
    while @taxable_balance >= @plan.annual_withdrawal_amount_taxable
      @taxable_balance -= @plan.annual_withdrawal_amount_taxable
      @tfsa_balance += @plan.annual_tfsa_contribution
      apply_growth
      print_yearly_status("Taxable Drawdown")
      @age += 1
    end
  end

  def simulate_tfsa_drawdown
    while @tfsa_balance >= @plan.annual_withdrawal_amount_tfsa
      @tfsa_balance -= @plan.annual_withdrawal_amount_tfsa
      apply_growth
      print_yearly_status("TFSA Drawdown")
      @age += 1
    end
  end

  def apply_growth
    @rrsp_balance *= (1 + @plan.annual_growth_rate)
    @taxable_balance *= (1 + @plan.annual_growth_rate)
    @tfsa_balance *= (1 + @plan.annual_growth_rate)
  end

  def print_yearly_status(note)
    puts format("%-10d %-20s %-20s %-20s %-20s",
                @age,
                format_currency(@rrsp_balance),
                format_currency(@tfsa_balance),
                format_currency(@taxable_balance),
                note)
  end

  def format_currency(amount)
    "$#{format('%.2f', amount).reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
  end
end

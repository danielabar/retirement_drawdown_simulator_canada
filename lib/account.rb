# frozen_string_literal: true

class Account
  attr_accessor :balance

  def initialize(balance)
    @balance = balance
  end

  def withdraw(amount)
    return 0 if balance < amount

    @balance -= amount
    amount
  end

  def deposit(amount)
    @balance += amount
  end

  def apply_growth(rate)
    @balance *= (1 + rate)
  end
end

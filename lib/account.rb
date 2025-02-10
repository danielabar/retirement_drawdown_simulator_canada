# frozen_string_literal: true

class Account
  # TODO: Should be read-only for public access?
  attr_accessor :balance

  def initialize(balance, given_rate = nil)
    @balance = balance
    @given_rate = given_rate
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
    rate_to_use = @given_rate || rate
    @balance *= (1 + rate_to_use)
  end
end

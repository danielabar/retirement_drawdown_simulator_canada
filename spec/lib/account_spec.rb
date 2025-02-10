# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Account do
  subject(:account) { described_class.new(initial_balance) }

  let(:initial_balance) { 10_000 }

  describe "#initialize" do
    it "sets the initial balance" do
      expect(account.balance).to eq(initial_balance)
    end
  end

  describe "#withdraw" do
    context "when there are sufficient funds" do
      it "reduces the balance by the withdrawn amount" do
        account.withdraw(2_000)
        expect(account.balance).to eq 8_000
      end

      it "returns the withdrawn amount" do
        expect(account.withdraw(3_000)).to eq 3_000
      end
    end

    context "when funds are insufficient" do
      it "does not change the balance" do
        expect { account.withdraw(15_000) }.not_to(change(account, :balance))
      end

      it "returns 0" do
        expect(account.withdraw(15_000)).to eq(0)
      end
    end
  end

  describe "#deposit" do
    it "increases the balance by the deposited amount" do
      account.deposit(1_000)
      expect(account.balance).to eq(11_000)
    end
  end

  describe "#apply_growth" do
    context "with positive growth rate" do
      it "increases the balance by 5%" do
        account.apply_growth(0.05)
        expect(account.balance).to be_within(0.01).of(10_500.00)
      end
    end

    context "with zero growth rate" do
      it "keeps the balance unchanged" do
        account.apply_growth(0)
        expect(account.balance).to eq(10_000.00)
      end
    end

    context "with negative growth rate" do
      it "decreases the balance by 10%" do
        account.apply_growth(-0.10)
        expect(account.balance).to be_within(0.01).of(9_000.00)
      end
    end

    context "when initialized with a given rate" do
      let(:account) { described_class.new(initial_balance, 0.03) }

      it "uses the given_rate instead of the provided rate" do
        account.apply_growth(0.05) # Should use 0.03 instead
        expect(account.balance).to be_within(0.01).of(10_300.00)
      end
    end
  end
end

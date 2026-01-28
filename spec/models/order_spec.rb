require "rails_helper"

RSpec.describe Order, type: :model do
  describe "customer_name attr" do
    it "has valid character" do
      orders = [
        Fabricate.build(:order, customer_name: ""),
        Fabricate.build(:order, customer_name: "ab"),
        Fabricate.build(:order, customer_name: "a" * 101),
        Fabricate.build(:order, customer_name: "contain\nnewline"),
        Fabricate.build(:order, customer_name: "contain [weird bracket]")
      ]

      orders.each { |o| o.save }

      expect(orders.map { |o| o.valid? }).to all(be(false))
      expect(orders.map { |o| o.errors.include?(:customer_name) }).to all(be(true))
    end
  end

  describe "customer_address attr" do
    it "has valid character" do
      orders = [
        Fabricate.build(:order, customer_address: nil),
        Fabricate.build(:order, customer_address: "a" * 1001),
        Fabricate.build(:order, customer_address: "contain [weird bracket]")
      ]

      orders.each { |o| o.save }

      expect(orders.map { |o| o.valid? }).to all(be(false))
      expect(orders.map { |o| o.errors.include?(:customer_address) }).to all(be(true))
    end
  end

  describe "status attr" do
    it "has valid status (enum :pending, :completed, :cancelled)" do
      expect { Order.new(status: "non_existing_symbol") }
        .to raise_error(ArgumentError)
    end
  end

  describe "total_amount (cents & currency) attr" do
    it "has valid total_amount_cents" do
      orders = [
        Fabricate.build(:order, total_amount: -1),
        Fabricate.build(:order, total_amount: "ab")
      ]

      orders.each { |o| o.save }

      expect(orders.map { |o| o.valid? }).to all(be(false))
      expect(orders.map { |o| o.errors.include?(:total_amount) }).to all(be(true))
    end

    it "setting total_amount_cents automatically add currency (default to USD)" do
      order = Fabricate.build(:order, total_amount: 1)

      order.save

      expect(order.total_amount_cents).to eq(100)
      expect(order.total_amount_currency).to eq("USD")
    end
  end
end

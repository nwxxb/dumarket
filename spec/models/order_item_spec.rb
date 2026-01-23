require "rails_helper"

RSpec.describe OrderItem, type: :model do
  describe "product_name attr" do
    it "has valid name" do
      order_items = [
        Fabricate.build(:order_item, product_name: ""),
        Fabricate.build(:order_item, product_name: "ab"),
        Fabricate.build(:order_item, product_name: "a" * 101),
        Fabricate.build(:order_item, product_name: "contain\nnewline"),
        Fabricate.build(:order_item, product_name: "contain [weird bracket]")
      ]

      order_items.each { |oi| oi.save }

      expect(order_items.map { |oi| oi.valid? }).to all(be(false))
      expect(order_items.map { |oi| oi.errors.include?(:product_name) }).to all(be(true))
    end
  end

  describe "product_description attr" do
    it "has valid description" do
      order_items = [
        Fabricate.build(:order_item, product_description: nil),
        Fabricate.build(:order_item, product_description: "a" * 1001),
        Fabricate.build(:order_item, product_description: "contain [weird bracket]")
      ]

      order_items.each { |oi| oi.save }

      expect(order_items.map { |oi| oi.valid? }).to all(be(false))
      expect(order_items.map { |oi| oi.errors.include?(:product_description) }).to all(be(true))
    end
  end

  describe "price_at_purchase (cents & currency) attr" do
    it "has valid price_at_purchase_cents" do
      order_items = [
        Fabricate.build(:order_item, price_at_purchase: -1),
        Fabricate.build(:order_item, price_at_purchase: "ab")
      ]

      order_items.each { |oi| oi.save }

      expect(order_items.map { |oi| oi.valid? }).to all(be(false))
      expect(order_items.map { |oi| oi.errors.include?(:price_at_purchase) }).to all(be(true))
    end

    it "setting price_at_purchase_cents automatically add currency (default to USD)" do
      order_item = Fabricate.build(:order_item, price_at_purchase: 1)

      order_item.save

      expect(order_item.price_at_purchase_cents).to eq(100)
      expect(order_item.price_at_purchase_currency).to eq("USD")
    end
  end

  describe "amount attr" do
    it "has valid amount" do
      order_items = [
        Fabricate.build(:order_item, amount: nil),
        Fabricate.build(:order_item, amount: 0),
        Fabricate.build(:order_item, amount: -1),
        Fabricate.build(:order_item, amount: "ab")
      ]

      order_items.each { |oi| oi.save }

      expect(order_items.map { |oi| oi.valid? }).to all(be(false))
      expect(order_items.map { |oi| oi.errors.include?(:amount) }).to all(be(true))
    end
  end
end

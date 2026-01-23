require "rails_helper"

RSpec.describe Product, type: :model do
  describe "name attr" do
    it "has valid name" do
      products = [
        Fabricate.build(:product, name: ""),
        Fabricate.build(:product, name: "ab"),
        Fabricate.build(:product, name: "a" * 101),
        Fabricate.build(:product, name: "contain\nnewline"),
        Fabricate.build(:product, name: "contain [weird bracket]")
      ]

      products.each { |p| p.save }

      expect(products.map(&:valid?)).to all(be(false))
      expect(products.map { |p| p.errors.include?(:name) }).to all(be(true))
    end
  end

  describe "description attr" do
    it "has valid description" do
      products = [
        Fabricate.build(:product, description: nil),
        Fabricate.build(:product, description: "a" * 1001),
        Fabricate.build(:product, description: "contain [weird bracket]")
      ]

      products.each { |p| p.save }

      expect(products.map(&:valid?)).to all(be(false))
      expect(products.map { |p| p.errors.include?(:description) }).to all(be(true))
    end
  end

  describe "price (price_cents & price_currency) attr" do
    it "has valid price_cents" do
      products = [
        Fabricate.build(:product, price: -1),
        Fabricate.build(:product, price: "ab")
      ]

      products.each { |p| p.save }

      expect(products.map(&:valid?)).to all(be(false))
      expect(products.map { |p| p.errors.include?(:price) }).to all(be(true))
    end

    it "setting price_cents automatically add currency (default to USD)" do
      product = Fabricate.build(:product, price: 1)

      result = product.save

      expect(result).to eq(true)
      expect(product.price_cents).to eq(100)
      expect(product.price_currency).to eq("USD")
    end
  end

  describe "discarded_at attr" do
    it "you can discard a product and it will fill the discarded_at" do
      product = Fabricate.build(:product, discarded: false)
      timestamp = 2.day.ago

      travel_to timestamp do
        product.discard!
      end

      expect(product.discarded?).to be(true)
      expect(product.discarded_at).to be_within(1.second).of(timestamp)
    end
  end
end

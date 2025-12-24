require 'rails_helper'

RSpec.describe Product, type: :model do
  it "has valid name" do
    products = [
      Fabricate.build(:product, name: ""),
      Fabricate.build(:product, name: "ab"),
      Fabricate.build(:product, name: "a" * 101),
      Fabricate.build(:product, name: "contain\nnewline"),
      Fabricate.build(:product, name: "contain [weird bracket]")
    ]

    result = products.map { |p| p.save }

    expect(result).to all(be(false))
  end

  it "has valid description" do
    products = [
      Fabricate.build(:product, description: nil),
      Fabricate.build(:product, description: "a" * 1001),
      Fabricate.build(:product, description: "contain [weird bracket]")
    ]

    result = products.map { |p| p.save }

    expect(result).to all(be(false))
  end

  it "has valid price_cents" do
    products = [
      Fabricate.build(:product, price_cents: -1),
      Fabricate.build(:product, price_cents: "ab")
    ]

    result = products.map { |p| p.save }

    expect(result).to all(be(false))
  end

  it "setting price_cents automatically add currency (default to USD)" do
    product = Fabricate.build(:product, price_cents: 1)

    result = product.save

    expect(result).to eq(true)
    expect(product.price_cents).to eq(1)
    expect(product.price_currency).to eq("USD")
  end
end

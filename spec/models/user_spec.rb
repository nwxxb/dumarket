require "rails_helper"

RSpec.describe User, type: :model do
  describe "#merge_cart_items_from_session" do
    it "update session_id to nil and fill user_id if product not exist" do
      user = Fabricate(:user)
      product = Fabricate(:product)
      session_id = SecureRandom.hex(16)
      cart_item = Fabricate(
        :cart_item, product: product, amount: 2,
        user: nil, session_id: session_id
      )

      user.merge_cart_items_from_session(session_id)

      expect(user.cart_items.length).to eq(1)
      expect(user.cart_items.map(&:id)).to eq([cart_item.id])
      cart_item.reload
      expect(cart_item.user_id).to eq(user.id)
      expect(cart_item.session_id).to eq(nil)
      expect(user.cart_items.map(&:product_id)).to eq([product.id])
      expect(user.cart_items.map(&:amount)).to eq([2])
    end

    it "increase amount if product already exist" do
      user = Fabricate(:user)
      product = Fabricate(:product)
      session_id = SecureRandom.hex(16)
      existing_cart_item = Fabricate(
        :cart_item, product: product, amount: 1,
        user: user, session_id: nil
      )
      existing_cart_item_2 = Fabricate(:cart_item, user: user, amount: 1)
      cart_item = Fabricate(
        :cart_item, product: product, amount: 2,
        user: nil, session_id: session_id
      )

      user.merge_cart_items_from_session(session_id)

      expect(user.cart_items.length).to eq(2)
      expect(user.cart_items.map(&:id)).to match_array([existing_cart_item.id, existing_cart_item_2.id])
      existing_cart_item.reload
      expect(existing_cart_item.amount).to eq(3)
      expect { cart_item.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect(user.cart_items.map(&:product_id)).to include(product.id)
      expect(user.cart_items.map(&:amount)).to match_array([3, 1])
    end

    it "rollback if one of query failed" do
      expect_any_instance_of(CartItem).to receive(:destroy).and_raise(ActiveRecord::RecordNotDestroyed)

      user = Fabricate(:user)
      session_id = SecureRandom.hex(16)
      product = Fabricate(:product)
      Fabricate(:cart_item, amount: 1, product: product, user: user, session_id: nil)
      Fabricate(:cart_item, amount: 2, product: product, user: nil, session_id: session_id)

      expect {
        user.merge_cart_items_from_session(session_id)
      }.to raise_error(ActiveRecord::RecordNotDestroyed)

      expect(user.cart_items.length).to eq(1)
      expect(user.cart_items.map(&:amount)).to match_array([1])
    end
  end
end

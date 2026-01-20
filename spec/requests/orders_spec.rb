require 'rails_helper'

RSpec.describe "Orders", type: :request do
  describe "GET /orders" do
    it "user need to authenticate" do
      get orders_path

      expect(response).to redirect_to(new_user_session_path)
    end

    it "fetch all orders" do
      user = Fabricate(:user)

      sign_in user
      get orders_path

      expect(response).to have_http_status(200)
    end
  end

  describe "GET /new" do
    it "user need to authenticate" do
      get new_order_path

      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirect to carts page if there is no item exist" do
      user = Fabricate(:user)
      product = Fabricate(:product, discarded: true)
      Fabricate(:cart_item, product: product, user: user)

      sign_in user
      get new_order_path

      expect(response).to redirect_to(cart_items_path)
    end
  end

  describe "POST /orders" do
    it "user need to authenticate" do
      post orders_path

      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirect to carts page if there is no item exist" do
      user = Fabricate(:user)
      product = Fabricate(:product, discarded: true)
      Fabricate(:cart_item, product: product, user: user)

      sign_in user
      post orders_path

      expect(response).to redirect_to(cart_items_path)
    end

    it "make order creation atomic" do
      user = Fabricate(:user)
      Fabricate(:cart_item, user: user)

      receive_count = 0
      allow_any_instance_of(OrderItem).to receive(:save) do
        receive_count += 1
      end.and_return(false)

      sign_in user
      post orders_path, params: {
        order: {
          customer_name: 'john', customer_address: 'somwhere',
          cart_signature: generate_cart_signature(user.cart_items)
        }
      }

      expect(receive_count).to eq(1)
      expect(response).to redirect_to(cart_items_path)
      user.reload
      expect(user.orders).to be_blank
    end

    it "prevent cart item and product mutation between new and create action" do
      user = Fabricate(:user)
      product = Fabricate(:product, price: 1)
      discarded_product = Fabricate(:product, price: 1)
      cart_item1 = Fabricate(:cart_item, product: product, amount: 1, user: user)
      cart_item2 = Fabricate(:cart_item, product: discarded_product, amount: 1, user: user)

      allow_any_instance_of(OrdersController).to receive(:create).and_wrap_original do |method|
        cart_item1.update(amount: 3)
        discarded_product.discard!
        method.call
      end

      sign_in user
      post orders_path, params: {
        order: {
          customer_name: 'john', customer_address: 'somwhere',
          cart_signature: generate_cart_signature(user.cart_items)
        }
      }

      expect(response).to redirect_to(cart_items_path)
      user.reload
      expect(user.orders).to be_blank
    end
  end

  def generate_cart_signature(cart_items)
    val = cart_items.map do |ci|
    [ ci.product_id, ci.amount, ci.product.price_cents, ci.product.price_currency, ci.product.discarded? ].join("-")
    end.sort.join("|")
    Rails.application.message_verifier(:cart_signature).generate(val)
  end
end

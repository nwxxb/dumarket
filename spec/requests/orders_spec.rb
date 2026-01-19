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

  describe "POSt /orders" do
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

      stubbed_order_items = double()
      allow(stubbed_order_items).to receive(:create!).and_raise(ActiveRecord::RecordInvalid)
      allow_any_instance_of(Order).to receive(:order_items).and_return(stubbed_order_items)

      sign_in user
      post orders_path, params: { order: { admin: true, customer_name: 'john', customer_address: 'somwhere' } }

      expect(stubbed_order_items).to have_received(:create!)
      expect(response).to have_http_status(422)
      user.reload
      expect(user.orders).to be_blank
    end
  end
end

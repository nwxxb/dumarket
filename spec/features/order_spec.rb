require 'rails_helper'

RSpec.feature "Order", type: :feature, js: true do
  describe "Post" do
    context "guest user" do
      it "need to sign in first" do
        product1 = Fabricate(:product, price_cents: 100, price_currency: 'USD')
        product2 = Fabricate(:product, price_cents: 100, price_currency: 'USD')
        user = Fabricate(:user)
        Fabricate(:cart_item, user: user, product: product1, amount: 1)
        Fabricate(:cart_item, user: user, product: product2, amount: 1)

        visit products_path
        find_link(href: product_path(product1)).click
        find(:test_id, 'add-to-cart').click

        visit cart_items_path

        find(:test_id, 'proceed-checkout').click

        expect(page).to have_current_path(new_user_session_path)

        simulate_sign_in(user.email, user.password)

        expect(page).to have_current_path(new_order_path)
        expect(page).to have_content(/2..*item/im)
        expect(page).to have_selector(:test_id, 'cart-items-total', text: '$3.00')
        within(:test_id, 'cart-item', text: product1.name) do
          expect(page).to have_selector(:test_id, 'cart-item-amount', text: "2")
        end
        within(:test_id, 'cart-item', text: product2.name) do
          expect(page).to have_selector(:test_id, 'cart-item-amount', text: "1")
        end
      end
    end

    context "authenticated user" do
      it "can create order" do
        product1 = Fabricate(:product, price_cents: 100, price_currency: 'USD')
        product2 = Fabricate(:product, price_cents: 100, price_currency: 'USD')
        discarded_product = Fabricate(:product, discarded: true)
        user = Fabricate(:user)
        Fabricate(:cart_item, user: user, product: product1, amount: 1)
        Fabricate(:cart_item, user: user, product: product2, amount: 1)
        Fabricate(:cart_item, user: user, product: discarded_product, amount: 1)

        sign_in user
        visit cart_items_path
        find(:test_id, 'proceed-checkout').click

        expect(page).to have_content(/2..*item/im)
        expect(page).to have_selector(:test_id, 'cart-items-total', text: '$2.00')
        within(:test_id, 'cart-item', text: product1.name) do
          expect(page).to have_selector(:test_id, 'cart-item-amount', text: "1")
        end
        within(:test_id, 'cart-item', text: product2.name) do
          expect(page).to have_selector(:test_id, 'cart-item-amount', text: "1")
        end
        expect(page).not_to have_selector(:test_id, 'cart-item', text: discarded_product.name)

        within("form#new_order[action='#{orders_path}']") do
          fill_in :order_customer_name, with: user.email
          fill_in :order_customer_address, with: 'an address'
          find_button(type: 'submit').click
        end

        expect(page).to have_current_path(orders_path)
        expect(page).to have_selector(:test_id, 'order-card', count: 1)
        within(:test_id, 'order-card') do
          expect(page).to have_selector(:test_id, 'order-status', text: 'pending')
          expect(page).to have_selector(:test_id, 'order-items-count', text: '2')
          expect(page).to have_selector(:test_id, 'order-total-amount', text: '$2.00')
        end
      end

      it "clean the cart items" do
        product1 = Fabricate(:product, price_cents: 100, price_currency: 'USD')
        product2 = Fabricate(:product, price_cents: 100, price_currency: 'USD')
        discarded_product = Fabricate(:product, discarded: true)
        user = Fabricate(:user)
        Fabricate(:cart_item, user: user, product: product1, amount: 1)
        Fabricate(:cart_item, user: user, product: product2, amount: 1)
        Fabricate(:cart_item, user: user, product: discarded_product, amount: 1)

        sign_in user
        visit cart_items_path
        find(:test_id, 'proceed-checkout').click

        within("form#new_order[action='#{orders_path}']") do
          fill_in :order_customer_name, with: user.email
          fill_in :order_customer_address, with: 'an address'
          find_button(type: 'submit').click
        end

        visit cart_items_path
        expect(page).to have_selector(:test_id, 'cart-item-card', count: 0)
      end
    end
  end

  describe "Index" do
    it "shows order" do
      user = Fabricate(:user)
      order1 = Fabricate(:order, user: user)
      order2 = Fabricate(:order, user: user)
      order3 = Fabricate(:order)

      sign_in user
      visit root_path
      find(:test_id, 'authenticated-user-dropdown').click
      find_link(href: orders_path).click

      expect(page).to have_selector(:test_id, 'order-card', count: 2)
      expect(page).to have_link(href: order_path(order1))
      expect(page).to have_link(href: order_path(order2))
      expect(page).not_to have_link(href: order_path(order3))
    end
  end

  describe "Show" do
    it "creating order will snapshot all cart item amount and it's product (excluding the discarded one)" do
      product1 = Fabricate(:product, name: 'sock', price_cents: 100, price_currency: 'USD')
      product2 = Fabricate(:product, price_cents: 100, price_currency: 'USD')
      discarded_product = Fabricate(:product, discarded: true)
      user = Fabricate(:user)
      cart_item1 = Fabricate(:cart_item, user: user, product: product1, amount: 1)
      cart_item2 = Fabricate(:cart_item, user: user, product: product2, amount: 2)
      cart_item2 = Fabricate(:cart_item, user: user, product: discarded_product, amount: 1)

      sign_in user
      visit cart_items_path
      find(:test_id, 'proceed-checkout').click

      within("form#new_order[action='#{orders_path}']") do
        fill_in :order_customer_name, with: user.email
        fill_in :order_customer_address, with: 'an address'
        find_button(type: 'submit').click
      end

      product1.update(name: 't-shirt')
      product2.discard!

      find(:test_id, 'order-card', text: "$3.00").click

      expect(page).to have_content('an address')
      expect(page).to have_content(user.email)
      expect(page).to have_content('sock')
      expect(page).not_to have_content('t-shirt')
      expect(page).to have_content(product2.name)
      expect(page).to have_content(product1.price.format)
      expect(page).to have_content(product2.price.format)
      expect(page).to have_content(cart_item1.amount)
      expect(page).to have_content(cart_item2.amount)
      expect(page).to have_content("pending")
      expect(page).to have_content("$3.00")
    end
  end
end

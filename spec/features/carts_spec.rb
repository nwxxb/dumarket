require 'rails_helper'

RSpec.feature "Cart Items", type: :feature, js: true do
  context "authenticated user" do
    it "can add products to cart" do
      product1 = Fabricate(:product, price_cents: 100, price_currency: 'USD')
      product2 = Fabricate(:product, price_cents: 100, price_currency: 'USD')
      user = Fabricate(:user)
      sign_in user

      visit products_path
      find_link(href: product_path(product1)).click
      find(:test_id, 'add-to-cart').click
      find(:test_id, 'add-to-cart').click

      expect(page).to have_current_path(product_path(product1))

      visit products_path
      find_link(href: product_path(product2)).click
      find(:test_id, 'add-to-cart').click

      expect(page).to have_current_path(product_path(product2))

      visit cart_items_path

      expect(page).to have_selector(:test_id, 'cart-item-card', count: 2)
      expect(page).to have_selector(:test_id, 'cart-items-total', text: '$3.00')
      expect(page).to have_content(/2..*item/im)
      within(:test_id, 'cart-item-card', text: product1.name) do
        expect(page).to have_selector(:test_id, 'cart-item-amount', text: "2")
      end
      within(:test_id, 'cart-item-card', text: product2.name) do
        expect(page).to have_selector(:test_id, 'cart-item-amount', text: "1")
      end
    end

    it "can update amount of a product in cart" do
      product1 = Fabricate(:product, price_cents: 100, price_currency: 'USD')
      user = Fabricate(:user)
      sign_in user

      visit products_path
      find_link(href: product_path(product1)).click
      find(:test_id, 'add-to-cart').click
      find(:test_id, 'add-to-cart').click

      visit cart_items_path

      within(:test_id, 'cart-item-card', text: product1.name) do
        find(:test_id, 'cart-item-increase-amount').click
        find(:test_id, 'cart-item-increase-amount').click
        find(:test_id, 'cart-item-decrease-amount').click
      end
      expect(page).to have_selector(:test_id, 'cart-item-card', count: 1)
      expect(page).to have_selector(:test_id, 'cart-items-total', text: '$3.00')
      expect(page).to have_content(/1..*item/im)
      within(:test_id, 'cart-item-card', text: product1.name) do
        expect(page).to have_selector(:test_id, 'cart-item-amount', text: "3")
      end
    end

    it "can remove a product in cart" do
      product1 = Fabricate(:product)
      user = Fabricate(:user)
      sign_in user

      visit products_path
      find_link(href: product_path(product1)).click
      find(:test_id, 'add-to-cart').click
      find(:test_id, 'add-to-cart').click

      visit cart_items_path

      within(:test_id, 'cart-item-card', text: product1.name) do
        find(:test_id, 'cart-item-delete').click
      end
      expect(page).to have_content(/1..*item/im)
      expect(page).to have_selector(:test_id, 'cart-item-card', count: 0)
      expect(page).to have_content(/product..*remove..*cart/im)
    end
  end

  context "guest user/unauthenticated user" do
    it "can add products to cart" do
      product1 = Fabricate(:product)
      product2 = Fabricate(:product)
      product3 = Fabricate(:product)
      Fabricate(:cart_item, product: product3, session_id: SecureRandom.hex(16))

      visit products_path
      find_link(href: product_path(product1)).click
      find(:test_id, 'add-to-cart').click
      find(:test_id, 'add-to-cart').click

      expect(page).to have_current_path(product_path(product1))

      visit products_path
      find_link(href: product_path(product2)).click
      find(:test_id, 'add-to-cart').click

      expect(page).to have_current_path(product_path(product2))

      visit cart_items_path

      expect(page).to have_selector(:test_id, 'cart-item-card', count: 2)
      expect(page).not_to have_selector(:test_id, 'cart-item-card', text: product3.name)
      within(:test_id, 'cart-item-card', text: product1.name) do
        expect(page).to have_selector(:test_id, 'cart-item-amount', text: "2")
      end
      within(:test_id, 'cart-item-card', text: product2.name) do
        expect(page).to have_selector(:test_id, 'cart-item-amount', text: "1")
      end
    end

    it "can update amount of a product in cart" do
      product1 = Fabricate(:product)

      visit products_path
      find_link(href: product_path(product1)).click
      find(:test_id, 'add-to-cart').click
      find(:test_id, 'add-to-cart').click

      visit cart_items_path

      within(:test_id, 'cart-item-card', text: product1.name) do
        find(:test_id, 'cart-item-increase-amount').click
        find(:test_id, 'cart-item-increase-amount').click
        find(:test_id, 'cart-item-decrease-amount').click
      end
      expect(page).to have_selector(:test_id, 'cart-item-card', count: 1)
      within(:test_id, 'cart-item-card', text: product1.name) do
        expect(page).to have_selector(:test_id, 'cart-item-amount', text: "3")
      end
    end

    it "can remove a product in cart" do
      product1 = Fabricate(:product)

      visit products_path
      find_link(href: product_path(product1)).click
      find(:test_id, 'add-to-cart').click
      find(:test_id, 'add-to-cart').click

      visit cart_items_path

      within(:test_id, 'cart-item-card', text: product1.name) do
        find(:test_id, 'cart-item-delete').click
      end
      expect(page).to have_selector(:test_id, 'cart-item-card', count: 0)
      expect(page).to have_content(/product..*remove..*cart/im)
    end

    it "sign in will merge all cart item to existing cart" do
      product1 = Fabricate(:product, price_cents: 100, price_currency: 'USD')
      product2 = Fabricate(:product, price_cents: 100, price_currency: 'USD')
      user = Fabricate(:user)
      Fabricate(:cart_item, product: product1, user: user)

      visit products_path
      find_link(href: product_path(product1)).click
      find(:test_id, 'add-to-cart').click

      visit products_path
      find_link(href: product_path(product2)).click
      find(:test_id, 'add-to-cart').click

      simulate_sign_in(user.email, user.password)

      visit cart_items_path

      expect(page).to have_selector(:test_id, 'cart-items-total', text: '$3.00')
      expect(page).to have_selector(:test_id, 'cart-item-card', count: 2)
      within(:test_id, 'cart-item-card', text: product1.name) do
        expect(page).to have_selector(:test_id, 'cart-item-amount', text: "2")
      end
      within(:test_id, 'cart-item-card', text: product2.name) do
        expect(page).to have_selector(:test_id, 'cart-item-amount', text: "1")
      end

      sign_out user
      visit cart_items_path
      expect(page).to have_selector(:test_id, 'cart-item-card', count: 0)
    end

    it "sign up will merge all cart item to existing cart" do
      product1 = Fabricate(:product, price_cents: 100, price_currency: 'USD')
      product2 = Fabricate(:product, price_cents: 200, price_currency: 'USD')
      user = Fabricate.build(:user)

      visit products_path
      find_link(href: product_path(product1)).click
      find(:test_id, 'add-to-cart').click
      find(:test_id, 'add-to-cart').click

      visit products_path
      find_link(href: product_path(product2)).click
      find(:test_id, 'add-to-cart').click

      simulate_sign_up(user.email, user.password, user.password)

      visit cart_items_path

      expect(page).to have_selector(:test_id, 'cart-item-card', count: 2)
      expect(page).to have_selector(:test_id, 'cart-items-total', text: '$4.00')
      within(:test_id, 'cart-item-card', text: product1.name) do
        expect(page).to have_selector(:test_id, 'cart-item-amount', text: "2")
      end
      within(:test_id, 'cart-item-card', text: product2.name) do
        expect(page).to have_selector(:test_id, 'cart-item-amount', text: "1")
      end

      sign_out user
      visit cart_items_path
      expect(page).to have_selector(:test_id, 'cart-item-card', count: 0)
    end
  end

  def simulate_sign_in(email, password)
    visit new_user_session_path
    within("form[action='#{user_session_path}']") do
      fill_in :user_email, with: email
      fill_in :user_password, with: password
      find_button(type: 'submit').click
    end
  end

  def simulate_sign_up(email, password, password_confirmation)
    visit new_user_registration_path
    within("form[action='#{user_registration_path}']") do
      fill_in :user_email, with: email
      fill_in :user_password, with: password
      fill_in :user_password_confirmation, with: password_confirmation
      find_button(type: 'submit').click
    end
  end
end

require 'rails_helper'

RSpec.feature "Orders (admin)", type: :feature, js: true do
  describe "index" do
    it "admin can list all orders" do
      user = Fabricate(:user, is_admin: true)
      orders = Fabricate.times(3, :order)

      sign_in user
      visit admin_root_path
      find_link(href: admin_orders_path).click

      orders.each do |o|
        expect(page).to have_content(o.id)
        expect(page).to have_content(o.status)
        expect(page).to have_content(o.customer_name)
        expect(page).to have_content(o.created_at)
        expect(page).to have_content(o.updated_at)
        expect(page).to have_link(href: admin_order_path(o))
      end
    end
  end

  describe "show" do
    it "admin can see details of an order" do
      user = Fabricate(:user, is_admin: true)
      order = Fabricate(:order)
      order_items = Fabricate.times(3, :order_item, order: order)

      sign_in user
      visit admin_orders_path
      find_link(href: admin_order_path(order)).click

      expect(page).to have_content(order.status)
      expect(page).to have_content(order.total_amount_cents)
      expect(page).to have_content(order.total_amount.format)
      expect(page).to have_content(order.customer_name)
      expect(page).to have_content(order.created_at)
      expect(page).to have_content(order.updated_at)
      expect(page).to have_field(:order_status)

      order_items.each do |oi|
        expect(page).to have_content(oi.amount)
        expect(page).to have_content(oi.product_name)
        expect(page).to have_content(oi.price_at_purchase.format)
      end
    end
  end

  describe "update" do
    it "admin can update a order status" do
      user = Fabricate(:user, is_admin: true)
      order = Fabricate(:order, status: 'pending')
      Fabricate(:order_item, order: order)

      sign_in user
      visit admin_orders_path
      find_link(href: admin_order_path(order)).click

      within("form[action='#{admin_order_path(order)}']") do
        select 'delivered', from: :order_status
        find_button(type: 'submit').click
      end

      expect(page).to have_current_path(admin_order_path(order))
      expect(page).not_to have_selector(:test_id, "order-status", text: 'pending')
      expect(page).to have_selector(:test_id, "order-status", text: 'delivered')
    end
  end
end

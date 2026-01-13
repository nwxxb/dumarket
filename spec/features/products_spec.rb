require 'rails_helper'

RSpec.feature "Products", type: :feature, js: true do
  describe "index" do
    it "user can see all products" do
      user = Fabricate(:user, is_admin: false)
      products = Fabricate.times(4, :product)
      removed_product = Fabricate(:product, discarded: true)

      sign_in user
      visit products_path

      products.each do |p|
        expect(page).to have_content(p.name)
        expect(page).to have_content(p.price)
        expect(page).to have_link(href: product_path(p))
      end
      expect(page).not_to have_content(removed_product.name)
      expect(page).not_to have_link(href: product_path(removed_product))
    end
  end

  describe "show" do
    it "user can see details of a product" do
      user = Fabricate(:user, is_admin: false)
      product = Fabricate(:product, images_count: 1)

      sign_in user
      visit products_path
      find_link(href: product_path(product)).click

      expect(page).to have_content(product.name)
      expect(page).to have_content(product.price)
      expect(page).to have_content(product.description)
      expect(page).to have_selector(:css, 'img')
    end

    it "user can't visit soft-deleted product" do
      user = Fabricate(:user, is_admin: false)
      removed_product = Fabricate(:product, discarded: true)

      sign_in user

      rails_responds_without_detailed_exceptions do
        visit product_path(removed_product)
      end

      expect(page).to have_current_path(product_path(removed_product))
      expect(page).to have_content("404")
      expect(page).to have_selector(:test_id, "user-navbar")
    end
  end
end

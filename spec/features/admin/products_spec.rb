require 'rails_helper'

RSpec.feature "Products (admin)", type: :feature, js: true do
  describe "index" do
    it "admin can list all products" do
      user = Fabricate(:user, is_admin: true)
      products = Fabricate.times(3, :product)

      sign_in user
      visit admin_root_path
      find_link(href: admin_products_path).click

      products.each do |p|
        expect(page).to have_content(p.name)
        expect(page).to have_content(p.price)
        expect(page).to have_content(p.created_at)
        expect(page).to have_content(p.updated_at)
        expect(page).to have_link(href: admin_product_path(p))
      end
    end
  end

  describe "show" do
    it "admin can see details of a product" do
      user = Fabricate(:user, is_admin: true)
      product = Fabricate(:product, images_count: 1)

      sign_in user
      visit admin_products_path
      find_link(href: admin_product_path(product)).click

      expect(page).to have_content(product.name)
      expect(page).to have_content(product.price)
      expect(page).to have_content(product.description)
      expect(page).to have_content(product.created_at)
      expect(page).to have_content(product.updated_at)
      expect(page).to have_link(href: edit_admin_product_path(product))
      expect(page).to have_selector(:css, 'img')
    end
  end

  describe "create" do
    it "admin can create a product" do
      user = Fabricate(:user, is_admin: true)
      product = Fabricate.build(:product)

      sign_in user
      visit admin_products_path
      find_link(href: new_admin_product_path).click

      within("form#new_product[action='#{admin_products_path}']") do
        fill_in :product_name, with: product.name
        fill_in :product_description, with: product.description
        fill_in :product_price_cents, with: product.price_cents
        find_button(type: 'submit').click
      end

      expect(page).to have_current_path(/#{admin_products_path + '/\d'}/)
      expect(page).to have_content(product.name)
      expect(page).to have_content(product.description)
      expect(page).to have_content(product.price)
      expect(page).to have_content(/no..*image/im)
    end

    it "invalid input" do
      user = Fabricate(:user, is_admin: true)

      sign_in user
      visit admin_products_path
      find_link(href: new_admin_product_path).click

      within("form[action='#{admin_products_path}']") do
        fill_in :product_name, with: ""
        find_button(type: 'submit').click
      end

      expect(page).to have_current_path(new_admin_product_path)
      expect(page).to have_content(/error/im)
    end
  end

  describe "update" do
    it "admin can update a product" do
      user = Fabricate(:user, is_admin: true)
      product = Fabricate(:product)
      new_product_data = Fabricate.build(:product)

      sign_in user
      visit admin_products_path
      find_link(href: admin_product_path(product)).click
      find_link(href: edit_admin_product_path(product)).click

      within("form[action='#{admin_product_path(product)}']") do
        attach_file Rails.root.join("spec/fixtures/files/simple_mountain.png") do
          find("[for='product_images']", visible: :all).click
        end
        fill_in :product_name, with: new_product_data.name
        fill_in :product_description, with: new_product_data.description
        fill_in :product_price_cents, with: new_product_data.price_cents
        find_button(type: 'submit').click
      end

      expect(page).to have_current_path(admin_product_path(product))
      expect(page).to have_content(new_product_data.name)
      expect(page).to have_content(new_product_data.price)
      expect(page).to have_content(new_product_data.description)
    end

    it "invalid input" do
      user = Fabricate(:user, is_admin: true)
      product = Fabricate(:product)

      sign_in user
      visit admin_products_path
      find_link(href: admin_product_path(product)).click
      find_link(href: edit_admin_product_path(product)).click

      within("form[action='#{admin_product_path(product)}']") do
        fill_in :product_name, with: ""
        find_button(type: 'submit').click
      end

      expect(page).to have_current_path(edit_admin_product_path(product))
      expect(page).to have_content(/error/im)
    end
  end

  describe "delete" do
    it "admin can destroy a product" do
      user = Fabricate(:user, is_admin: true)
      product = Fabricate(:product)
      existing_product = Fabricate(:product)

      sign_in user
      visit admin_products_path
      find_link(href: admin_product_path(product)).click
      find_link('delete').click

      expect(page).to have_current_path(admin_products_path)
      expect(page).not_to have_content(product.id)
      expect(page).not_to have_content(product.name)
      expect(page).not_to have_link(href: admin_product_path(product))
      expect(page).to have_content(existing_product.id)
      expect(page).to have_content(existing_product.name)
      expect(page).to have_link(href: admin_product_path(existing_product))
      expect(page).to have_content(/product..*deleted/im)
    end
  end
end

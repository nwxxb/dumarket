require 'rails_helper'

RSpec.feature "Users", type: :feature, js: true do
  describe "Register" do
    it "register and automatically logged in" do
      user = Fabricate.build(:user, password: 'password123')

      simulate_sign_up(user.email, 'password123', 'password123')

      expect(page).to have_current_path(root_path)
      find(:test_id, "authenticated-user-dropdown").click
      expect(page).not_to have_link(href: new_user_session_path)
      expect(page).not_to have_link(href: new_user_registration_path)
      expect(page).to have_link(href: destroy_user_session_path)
      expect(page).to have_content(user.email)
    end

    it "input invalid" do
      user = Fabricate.build(:user, password: 'password123')

      simulate_sign_up(user.email, 'password123', 'invalid-confirmation-pass')

      expect(page).to have_current_path(new_user_registration_path)
      expect(page).not_to have_link(href: destroy_user_session_path)
      expect(page).to have_content(/error..*password confirmation/im)
    end
  end

  describe "Edit profile" do
    it "user successfully update it's own user data" do
      old_password = "old_password"
      user = Fabricate(:user, password: old_password)
      new_password = "new_password"

      sign_in user

      visit edit_user_registration_path

      within("form#edit_user[action='#{user_registration_path}']") do
        attach_file Rails.root.join("spec/fixtures/files/simple_mountain.png") do
          find("[for='user_avatar']", visible: :all).click
        end
        fill_in :user_email, with: user.email
        fill_in :user_password, with: new_password
        fill_in :user_password_confirmation, with: new_password
        fill_in :user_current_password, with: old_password
        find_button(type: 'submit').click
      end

      expect(page).to have_current_path(user_profile_path)
      expect(page).to have_content(user.email)
    end

    it "cannot provide current_password" do
      user = Fabricate(:user)

      sign_in user

      visit edit_user_registration_path

      within("form#edit_user[action='#{user_registration_path}']") do
        fill_in :user_current_password, with: "invalid password"
        find_button(type: 'submit').click
      end

      expect(page).to have_current_path(edit_user_registration_path)
      expect(page).to have_content(/error..*password/im)
    end
  end

  describe "Delete/Destroy user" do
    it "user successfully update it's own user data" do
      user = Fabricate(:user)

      sign_in user

      visit edit_user_registration_path

      find_button('Cancel my account').click

      expect(page).to have_current_path(root_path)
      expect(page).to have_content(/account..*cancelled/im)
      expect(page).not_to have_content(user.email)
      expect(page).to have_link(href: new_user_session_path)
      expect(page).to have_link(href: new_user_registration_path)
    end
  end

  describe "forget password" do
    it "user successfully update it's own user data" do
      user = Fabricate(:user)
      new_password = "new_password"

      visit new_user_password_path

      within("form[action='#{user_password_path}']") do
        fill_in :user_email, with: user.email
        find_button(type: 'submit').click
      end

      expect(page).to have_current_path(new_user_session_path)
      expect(page).to have_content(/receive..*email..*instruction/im)
      user.reload
      email_body = ActionMailer::Base.deliveries.last.body.to_s
      hashed_token = email_body.match(/reset_password_token=([^&\s]+)">/)[1]
      visit edit_user_password_path(reset_password_token: hashed_token)

      within("form[action='#{user_password_path}']") do
        fill_in :user_password, with: new_password
        fill_in :user_password_confirmation, with: new_password
        find_button(type: 'submit').click
      end

      user.reload
      expect(user.valid_password?(new_password)).to be(true)
    end
  end
end

require 'rails_helper'

RSpec.feature "Auths", type: :feature, js: true do
  it "Log in and Log out" do
    user = Fabricate(:user, password: 'password123')

    simulate_sign_in(user.email, 'password123')

    expect(page).to have_current_path(root_path)
    find(:test_id, "authenticated-user-dropdown").click
    expect(page).not_to have_link(href: new_user_session_path)
    expect(page).not_to have_link(href: new_user_registration_path)
    expect(page).to have_link(href: destroy_user_session_path)
    expect(page).to have_content(user.email)

    find_link(href: destroy_user_session_path).click

    expect(page).to have_current_path(root_path)
    expect(page).to have_link(href: new_user_session_path)
    expect(page).to have_link(href: new_user_registration_path)
    expect(page).not_to have_link(href: destroy_user_session_path)
    expect(page).not_to have_content(user.email)
  end
end

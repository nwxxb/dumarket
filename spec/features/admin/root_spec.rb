require 'rails_helper'

RSpec.feature "Roots (admin)", type: :feature, js: true do
  it "admin can access admin root path" do
    user = Fabricate(:user, password: 'password123', is_admin: true)

    sign_in user
    visit admin_root_path

    expect(page).to have_current_path(admin_root_path)
    expect(page).to have_content(/admin..*dashboard/im)
    expect(page).to have_selector(:test_id, "admin-navbar")
  end

  it "normal user can't access normal root path" do
    user = Fabricate(:user, password: 'password123', is_admin: false)

    sign_in user
    rails_responds_without_detailed_exceptions do
      visit admin_root_path
    end

    expect(page).to have_current_path(admin_root_path)
    expect(page).to have_content("404")
    expect(page).to have_selector(:test_id, "user-navbar")
  end
end

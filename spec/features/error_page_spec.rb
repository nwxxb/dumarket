require "rails_helper"

RSpec.feature "Errors" do
  ErrorsController::ADDRESSED_ERROR_CODE.each do |http_code_str|
    it "handle #{http_code_str}", js: true do
      visit "/#{http_code_str}"

      expect(page.status_code).to eq(http_code_str.to_i)
      expect(page).to have_content(http_code_str)
    end
  end

  it "handle not found route error, show the user navbar (no user logged in)", js: true do
    rails_responds_without_detailed_exceptions do
      visit "/alsjfdksaklfdj"
    end

    expect(page.status_code).to eq(404)
    expect(page).to have_content(404)
    expect(page).to have_selector(:test_id, "user-navbar")
  end

  it "handle not found route error, show the user navbar (user)", js: true do
    user = Fabricate(:user)

    sign_in user

    rails_responds_without_detailed_exceptions do
      visit "/alsjfdksaklfdj"
    end

    expect(page.status_code).to eq(404)
    expect(page).to have_content(404)
    expect(page).to have_selector(:test_id, "user-navbar")
  end

  it "handle not found route error, show the user navbar (admin)", js: true do
    admin = Fabricate(:user, is_admin: true)

    sign_in admin

    rails_responds_without_detailed_exceptions do
      visit "/alsjfdksaklfdj"
    end

    expect(page.status_code).to eq(404)
    expect(page).to have_content(404)
    expect(page).to have_selector(:test_id, "user-navbar")
  end

  it "handle not found route error in admin page, show the user navbar (no-user)", js: true do
    rails_responds_without_detailed_exceptions do
      visit "admin/alsjfdksaklfdj"
    end

    expect(page.status_code).to eq(404)
    expect(page).to have_content(404)
    expect(page).to have_selector(:test_id, "user-navbar")
  end

  it "handle not found route error in admin page, show the user navbar (user)", js: true do
    admin = Fabricate(:user)

    sign_in admin

    rails_responds_without_detailed_exceptions do
      visit "admin/alsjfdksaklfdj"
    end

    expect(page.status_code).to eq(404)
    expect(page).to have_content(404)
    expect(page).to have_selector(:test_id, "user-navbar")
  end

  it "handle not found route error in admin page, show the admin navbar (admin)", js: true do
    admin = Fabricate(:user, is_admin: true)

    sign_in admin

    rails_responds_without_detailed_exceptions do
      visit "admin/alsjfdksaklfdj"
    end

    expect(page.status_code).to eq(404)
    expect(page).to have_content(404)
    expect(page).to have_selector(:test_id, "admin-navbar")
  end
end

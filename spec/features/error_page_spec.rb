require "rails_helper"

RSpec.feature "Errors" do
  ErrorsController::ADDRESSED_ERROR_CODE.each do |http_code_str|
    it "handle #{http_code_str}", js: true do
      visit "/#{http_code_str}"

      expect(page.status_code).to eq(http_code_str.to_i)
      expect(page).to have_content(http_code_str)
    end
  end

  it "handle not found route error, show the custom page", js: true do
    rails_responds_without_detailed_exceptions do
      visit "/alsjfdksaklfdj"
    end

    expect(page.status_code).to eq(404)
    expect(page).to have_content(404)
    expect(page).to have_selector(".navbar")
  end
end

require 'rails_helper'

RSpec.feature "Roots", type: :feature do
  it "show something" do
    visit root_path

    expect(page).to have_content('Welcome to Dumarket')
  end
end

module AuthHelpers
  def simulate_sign_in(email, password)
    visit new_user_session_path
    within("form[action='#{user_session_path}']") do
      fill_in :user_email, with: email
      fill_in :user_password, with: password
      find_button(type: "submit").click
    end
  end

  def simulate_sign_up(email, password, password_confirmation)
    visit new_user_registration_path
    within("form[action='#{user_registration_path}']") do
      fill_in :user_email, with: email
      fill_in :user_password, with: password
      fill_in :user_password_confirmation, with: password_confirmation
      find_button(type: "submit").click
    end
  end
end

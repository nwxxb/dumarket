Fabricator(:user) do
  transient :username

  username do
    "person_#{Fabricate.sequence :username}"
  end

  email { |attrs| "#{attrs[:username]}@example.com" }
  password { "password" }
  is_admin { false }
end

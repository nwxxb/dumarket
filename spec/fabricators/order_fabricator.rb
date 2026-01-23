Fabricator(:order) do
  user fabricator: :user
  status "pending"
  total_amount_cents 1
  items_count 1
  total_amount_currency "USD"
  customer_name do |attrs|
    attrs[:user].presence&.email
  end
  customer_address "an Address"
end

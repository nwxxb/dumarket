Fabricator(:cart_item) do
  user       { nil }
  session_id do |attrs|
    # trivial, not important: build same session if user exist
    if attrs[:user].present?
      nil
    else
      SecureRandom.hex(16)
    end
  end
  product
  amount 1
end

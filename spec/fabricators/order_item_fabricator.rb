Fabricator(:order_item) do
  order               fabricator: :order
  product             fabricator: :product
  amount              1

  price_at_purchase do |attrs|
    if attrs[:price_at_purchase].present?
      attrs[:price_at_purchase]
    elsif attrs[:product].present?
      attrs[:product].price
    end
  end

  product_name do |attrs|
    if attrs[:product_name].present?
      attrs[:product_name]
    elsif attrs[:product].present?
      attrs[:product].name
    end
  end

  product_description do |attrs|
    if attrs[:product_description].present?
      attrs[:product_description]
    elsif attrs[:product].present?
      attrs[:product].description
    end
  end
end

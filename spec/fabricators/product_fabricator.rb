Fabricator(:product) do
  transient :images_count
  transient :discarded
  images_count { 0 }
  discarded { false }

  name { "product_#{Fabricate.sequence :product}" }
  description { |attrs| "description for #{attrs[:name]}" }
  price do |attrs|
    Money.from_cents(
      attrs[:price_cents] || 100,
      attrs[:price_currency] || "USD"
    )
  end
  discarded_at { |attrs| (attrs[:discarded] == true) ? Time.current : nil }

  after_create do |product, transients|
    transients[:images_count].to_i.times do |i|
      product.images.attach(
        io: File.new(Rails.root.join("spec/fixtures/files/simple_mountain.png")),
        filename: "#{product.name}_image_#{i}",
        content_type: "image/png"
      )
    end
  end
end

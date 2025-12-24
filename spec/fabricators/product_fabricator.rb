Fabricator(:product) do
  transient :images_count

  images_count do
    0
  end

  name { "product_#{Fabricate.sequence :product}" }
  description { |attrs| "description for #{attrs[:name]}" }
  price_cents { 100 }
  price_currency { "USD" }

  after_create do |product, transients|
    (transients[:images_count].to_i || 0).times do |i|
      product.images.attach(
        io: File.new(Rails.root.join('spec', 'fixtures', 'files', 'simple_mountain.png')),
        filename: "#{product.name}_image_#{i}",
        content_type: "image/png",
      )
    end
  end
end

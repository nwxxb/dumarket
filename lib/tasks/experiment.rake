SIZE_OPTIONS = [:small, :medium]
USER_RATIO = {
  non_active: 35.to_f / 100,
  normal: 60.to_f / 100,
  hyper_active: 5.to_f / 100
}
TABLES_TARGET_SIZES = {
  users: {small: 100, medium: 1_000},
  products: {small: 1000, medium: 50_000}
}
ASSOCIATIONS_TARGET_SIZES = {
  normal: {cart_items_per_user: 2, orders_per_user: 5, order_items_per_order: 3},
  hyper_active: {cart_items_per_user: 20, orders_per_user: 50, order_items_per_order: 15}
}
FIXED_PRODUCT_PRICE_CENTS = 1000
FIXED_PRODUCT_PRICE_CURRENCY = "USD"
FAKE_PASSWORD = "password123"
SAMPLE_EACH_SEGMENT_AMOUNT = 1

namespace :experiment do
  desc "seed 'production-amount' of data for the experiment"
  task seed_bunch_of_data: [:environment] do |t|
    puts "running #{t} ..."

    if Rails.env.production?
      abort "currently in production environment"
    end

    Rake::Task["db:seed:replant"].invoke

    if !SIZE_OPTIONS.include?(ENV["SIZE"]&.downcase&.to_sym)
      abort "invalid size flag"
    end

    size = ENV["SIZE"]&.downcase&.to_sym

    $stdout.puts "1. Creating users...."

    users = []
    common_password_hash = Devise::Encryptor.digest(User, FAKE_PASSWORD)
    TABLES_TARGET_SIZES[:users][size].times do |i|
      date = Time.current + i.minutes

      users << {
        email: "person_#{i}@example.com",
        encrypted_password: common_password_hash,
        is_admin: false,
        created_at: date,
        updated_at: date
      }
    end

    User.where(is_admin: true).update_all(encrypted_password: common_password_hash)

    User.import users, validate: false
    $stdout.puts "sucessfully creating #{User.count} users"

    $stdout.puts "1. Creating products...."

    products = []
    TABLES_TARGET_SIZES[:products][size].times do |i|
      date = Time.current + i.minutes

      products << {
        name: "product_#{i}",
        description: "description for product_#{i}",
        price_cents: FIXED_PRODUCT_PRICE_CENTS,
        price_currency: FIXED_PRODUCT_PRICE_CURRENCY,
        created_at: date,
        updated_at: date
      }
    end

    Product.import products, validate: false
    $stdout.puts "sucessfully creating #{Product.count} products"

    sql = <<~SQL
      with sampled as (
      	select id, email from users tablesample bernoulli (?) where is_admin = false
      ),
      randomized_sample as (
      	select *, percent_rank() over (order by random()) as pos from sampled
      ),
      labelled_sample as (
      	select *, case
      		when pos < ? then 'normal'
      		else 'hyper_active'
      	end as label
      	from randomized_sample
      )
      select id, email, label from labelled_sample
    SQL

    randomized_users = User.find_by_sql([
      sql,
      (USER_RATIO[:normal] + USER_RATIO[:hyper_active]) * 100,
      USER_RATIO[:normal] / (USER_RATIO[:normal] + USER_RATIO[:hyper_active])
    ])
    $stdout.puts "sucessfully label #{randomized_users.count} user as normal/hyper_active"

    sampled_users = randomized_users.group_by { |user| user.label }
    User.where(id: sampled_users["normal"].pluck(:id)).update_all("email = CONCAT('normal_', email)")
    User.where(id: sampled_users["hyper_active"].pluck(:id)).update_all("email = CONCAT('hyper_active_', email)")

    products_ids = Product.ids

    cart_items = []
    orders = []
    $stdout.puts "Building cart_items, order, and order_items..."
    randomized_users.each do |user|
      # create cart items based on user label
      last_index = nil
      current_index = nil
      ASSOCIATIONS_TARGET_SIZES[user.label.to_sym][:cart_items_per_user].times do |i|
        current_index = rand(products_ids.length)

        if current_index == last_index
          current_index = (current_index + 1) % products_ids.length
        end

        last_index = current_index
        selected_product_id = products_ids[current_index]

        cart_items << {
          user_id: user.id,
          product_id: selected_product_id,
          session_id: nil,
          amount: rand(1..5)
        }
      end

      ASSOCIATIONS_TARGET_SIZES[user.label.to_sym][:orders_per_user].times do |i|
        user_order_items = []
        last_index = nil
        current_index = nil
        ASSOCIATIONS_TARGET_SIZES[user.label.to_sym][:order_items_per_order].times do |j|
          current_index = rand(products_ids.length)

          if current_index == last_index
            current_index = (current_index + 1) % products_ids.length
          end

          last_index = current_index
          selected_product_id = products_ids[current_index]

          user_order_items << OrderItem.new(
            amount: 1,
            product_id: selected_product_id,
            price_at_purchase_cents: FIXED_PRODUCT_PRICE_CENTS,
            price_at_purchase_currency: FIXED_PRODUCT_PRICE_CURRENCY,
            product_name: "product_name_at_purchase_(#{user.id}_#{i})",
            product_description: "product description at purchase (#{user.id}_#{i}_#{j})"
          )
        end
        order = Order.new(
          user_id: user.id,
          status: Order.statuses.values.sample,
          customer_name: user.email,
          customer_address: "an address (#{user.id}_#{i})",
          items_count: user_order_items.length,
          total_amount_cents: user_order_items.length * FIXED_PRODUCT_PRICE_CENTS,
          total_amount_currency: FIXED_PRODUCT_PRICE_CURRENCY
        )

        order.order_items = user_order_items
        orders << order
      end
    end

    $stdout.puts "3. Creating #{cart_items.length} cart_items...."
    CartItem.import cart_items, validate: false

    $stdout.puts "4. Creating #{orders.length} orders & their order_items...."
    Order.import orders, recursive: true, validate: false, batch_size: 1000

    $stdout.puts "5. take some users and put it in tmp/segmented_users.json files..."
    # workaround for filtered password attribute
    sql = ActiveRecord::Base.send(:sanitize_sql_array, [<<~SQL, {fake_password: FAKE_PASSWORD, sample_each_segment: SAMPLE_EACH_SEGMENT_AMOUNT}])
      SELECT id, email, password, is_admin FROM (
        (select id, email, is_admin, :fake_password as password, 0 as order_priority from users where is_admin = true limit :sample_each_segment)
        UNION
        (select id, email, is_admin, :fake_password as password, 1 as order_priority from users where email LIKE 'person%' limit :sample_each_segment)
        UNION
        (select id, email, is_admin, :fake_password as password, 2 as order_priority from users where email LIKE 'normal%' limit :sample_each_segment)
        UNION
        (select id, email, is_admin, :fake_password as password, 3 as order_priority from users where email LIKE 'hyper_active%' limit :sample_each_segment)
      ) t ORDER BY t.order_priority
    SQL
    json_result = ActiveRecord::Base.connection.select_all(sql).to_json
    File.write("tmp/segmented_users.json", json_result)
  end
end

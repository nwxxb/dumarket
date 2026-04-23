require "csv"

SIZE_OPTIONS = [:small, :medium, :big]
USER_RATIO = {
  non_active: 35.to_f / 100,
  normal: 60.to_f / 100,
  hyper_active: 5.to_f / 100
}
TABLES_TARGET_SIZES = {
  users: {small: 100, medium: 1_000, big: 10_000},
  products: {small: 1000, medium: 50_000, big: 500_000}
}
ASSOCIATIONS_TARGET_SIZES = {
  normal: {cart_items_per_user: 2, orders_per_user: 5, order_items_per_order: 3},
  hyper_active: {cart_items_per_user: 20, orders_per_user: 50, order_items_per_order: 15}
}
FAKE_PASSWORD = "password123"
FIXED_PRODUCT_PRICE_CENTS = 1000
FIXED_PRODUCT_PRICE_CURRENCY = "USD"
USER_AMOUNT_USED_AS_VU = 100

def copy_to_postgres(table_name, columns, &block)
  conn = ActiveRecord::Base.connection.raw_connection

  conn.copy_data "COPY #{table_name} (#{columns.join(",")}) FROM STDIN CSV" do
    yield(conn)
  end
end

def choose_unique_product_id(product_ids, last_index)
  current_index = rand(product_ids.length)

  if current_index == last_index
    current_index = (current_index + 1) % product_ids.length
  end

  [product_ids[current_index], last_index]
end

namespace :experiment do
  desc "seed 'production-amount' of data for the experiment (faster)"
  task seed_fake_data: [:environment] do |t|
    puts "running #{t} ..."

    if Rails.env.production?
      abort "currently in production environment"
    end

    $stdout.puts "0. truncating database..."
    tables_truncation_targets = ActiveRecord::Base.connection.tables - ["schema_migrations", "ar_internal_metadata"]
    ActiveRecord::Base.connection.execute("TRUNCATE #{tables_truncation_targets.join(", ")} RESTART IDENTITY CASCADE")

    if !SIZE_OPTIONS.include?(ENV["SIZE"]&.downcase&.to_sym)
      abort "invalid size flag"
    end

    size = ENV["SIZE"]&.downcase&.to_sym

    $stdout.puts "1. Creating users...."
    common_password_hash = Devise::Encryptor.digest(User, FAKE_PASSWORD)
    copy_to_postgres(:users, [:email, :encrypted_password, :is_admin, :created_at, :updated_at]) do |conn|
      # create admin user (currently only a single admin, we can add later if we want to benchmark admin page)
      date = Time.current
      row = CSV.generate_line([
        "admin@dumarket.com",
        common_password_hash,
        true,
        date,
        date
      ])

      conn.put_copy_data row

      # create non_admin user
      TABLES_TARGET_SIZES[:users][size].times do |i|
        date = Time.current + i.seconds
        row = CSV.generate_line([
          "person_#{i}@example.com",
          common_password_hash,
          false,
          date,
          date
        ])

        conn.put_copy_data row
      end
    end

    # imagine 100 jars and we have to divide those two 3 categories:
    # left jars for non-active, middle jar for normal, and right jars for hyper_active
    # these binds work as divider to those groups
    segmenting_binds = {
      active_start: (USER_RATIO[:non_active] * 100).round + 1,
      normal_end: ((USER_RATIO[:non_active] + USER_RATIO[:normal]) * 100).round
    }
    sql = ActiveRecord::Base.sanitize_sql_array([<<~SQL, segmenting_binds])
      with base_tiles as (
        select id, email, ntile(100) over (order by id) as tile
        from users
        where is_admin = false
      )
      select id, email, case
        when tile <= :normal_end then 'normal'
        else 'hyper_active'
      end as label
      from base_tiles
      where tile >= :active_start
    SQL

    randomized_users = ActiveRecord::Base.connection.select_all(sql)
    $stdout.puts "sucessfully label #{randomized_users.count} user as normal/hyper_active"

    sampled_users = randomized_users.group_by { |user| user["label"] }
    User.where(id: sampled_users["normal"].pluck("id")).update_all("email = CONCAT('normal_', email)")
    User.where(id: sampled_users["hyper_active"].pluck("id")).update_all("email = CONCAT('hyper_active_', email)")
    sampled_users = nil

    $stdout.puts "2. Creating products...."
    copy_to_postgres(:products, [:name, :description, :price_cents, :price_currency, :created_at, :updated_at]) do |conn|
      TABLES_TARGET_SIZES[:products][size].times do |i|
        date = Time.current + i.seconds
        row = CSV.generate_line([
          "product #{i}",
          "description for product #{i}",
          FIXED_PRODUCT_PRICE_CENTS,
          FIXED_PRODUCT_PRICE_CURRENCY,
          date,
          date
        ])

        conn.put_copy_data row
      end
    end

    product_ids = Product.ids

    $stdout.puts "3. Creating cart_items...."
    copy_to_postgres(:cart_items, [:user_id, :product_id, :session_id, :amount, :created_at, :updated_at]) do |conn|
      randomized_users.each do |user|
        last_product_index = nil
        ASSOCIATIONS_TARGET_SIZES[user["label"].to_sym][:cart_items_per_user].times do |i|
          selected_product_id, last_product_index = choose_unique_product_id(product_ids, last_product_index)

          date = Time.current + i.seconds
          row = CSV.generate_line([
            user["id"],
            selected_product_id,
            nil,
            rand(1..5),
            date,
            date
          ])

          conn.put_copy_data row
        end
      end
    end

    $stdout.puts "4. Creating orders...."
    copy_to_postgres(:orders, [:user_id, :status, :total_amount_cents, :total_amount_currency, :items_count, :customer_name, :customer_address, :created_at, :updated_at]) do |conn|
      randomized_users.each do |user|
        ASSOCIATIONS_TARGET_SIZES[user["label"].to_sym][:orders_per_user].times do |i|
          order_items_per_order = ASSOCIATIONS_TARGET_SIZES[user["label"].to_sym][:order_items_per_order]
          date = Time.current + i.seconds
          row = CSV.generate_line([
            user["id"],
            Order.statuses.values.sample,
            order_items_per_order * FIXED_PRODUCT_PRICE_CENTS,
            FIXED_PRODUCT_PRICE_CURRENCY,
            order_items_per_order,
            user["email"],
            "an address of (#{user["id"]})",
            date,
            date
          ])

          conn.put_copy_data row
        end
      end
    end

    $stdout.puts "5. Creating order_items...."
    copy_to_postgres(:order_items, [:order_id, :product_id, :amount, :price_at_purchase_cents, :price_at_purchase_currency, :product_name, :product_description, :created_at, :updated_at]) do |conn|
      last_order_index = 1
      randomized_users.each do |user|
        current_user_order_offset = ASSOCIATIONS_TARGET_SIZES[user["label"].to_sym][:orders_per_user]
        order_ids = (last_order_index...(last_order_index + current_user_order_offset)).to_a
        last_order_index += current_user_order_offset

        last_product_index = nil
        order_ids.each do |order_id|
          ASSOCIATIONS_TARGET_SIZES[user["label"].to_sym][:order_items_per_order].times do |i|
            selected_product_id, last_product_index = choose_unique_product_id(product_ids, last_product_index)
            date = Time.current + i.seconds

            row = CSV.generate_line([
              order_id,
              selected_product_id,
              1,
              FIXED_PRODUCT_PRICE_CENTS,
              FIXED_PRODUCT_PRICE_CURRENCY,
              "product_name_at_purchase_(#{user["id"]}_#{i})",
              "product description at purchase (#{user["id"]}_#{i}_#{j})",
              date,
              date
            ])

            conn.put_copy_data row
          end
        end
      end
    end

    $stdout.puts "6. take some users and put it in tmp/segmented_users.json files..."
    # workaround for filtered password attribute
    sample_binds = {
      non_active_user_sample_amount: USER_AMOUNT_USED_AS_VU * USER_RATIO[:non_active],
      normal_user_sample_amount: USER_AMOUNT_USED_AS_VU * USER_RATIO[:normal],
      hyper_active_user_sample_amount: USER_AMOUNT_USED_AS_VU * USER_RATIO[:hyper_active]
    }
    sql = ActiveRecord::Base.send(:sanitize_sql_array, [<<~SQL, sample_binds.merge(fake_password: FAKE_PASSWORD)])
      with sampled_users as (
        SELECT id, email, password, is_admin FROM (
          (select id, email, is_admin, :fake_password as password, 0 as order_priority from users where is_admin = true limit 5)
          UNION
          (select id, email, is_admin, :fake_password as password, 1 as order_priority from users where email LIKE 'person%' limit :non_active_user_sample_amount)
          UNION
          (select id, email, is_admin, :fake_password as password, 2 as order_priority from users where email LIKE 'normal%' limit :normal_user_sample_amount)
          UNION
          (select id, email, is_admin, :fake_password as password, 3 as order_priority from users where email LIKE 'hyper_active%' limit :hyper_active_user_sample_amount)
        ) t ORDER BY t.order_priority
      )
      select * from sampled_users ORDER BY hashint8extended(id, 42)
    SQL
    json_result = ActiveRecord::Base.connection.select_all(sql).to_json
    File.write("tmp/segmented_users.json", json_result)
  end
end

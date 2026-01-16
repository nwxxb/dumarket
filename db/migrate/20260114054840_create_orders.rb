class CreateOrders < ActiveRecord::Migration[7.2]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.monetize :total_amount
      t.string :status, null: false, default: "pending"
      t.string :customer_name, null: false
      t.text :customer_address, null: false
      t.integer :items_count, null: false, default: 0

      t.timestamps
    end
  end
end

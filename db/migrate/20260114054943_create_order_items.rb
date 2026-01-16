class CreateOrderItems < ActiveRecord::Migration[7.2]
  def change
    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: true
      t.references :product, null: true, foreign_key: false
      t.integer :amount, null: false
      t.monetize :price_at_purchase
      t.string :product_name, null: false
      t.text :product_description, null: false, default: ""

      t.timestamps
    end
  end
end

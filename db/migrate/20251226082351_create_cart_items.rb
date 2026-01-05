class CreateCartItems < ActiveRecord::Migration[7.2]
  def change
    create_table :cart_items do |t|
      t.references :user, null: true, foreign_key: true
      t.string :session_id, null: true
      t.references :product, null: false, foreign_key: true
      t.integer :amount, null: false, default: 0

      t.timestamps
    end
  end
end

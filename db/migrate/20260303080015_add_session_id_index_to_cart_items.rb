class AddSessionIdIndexToCartItems < ActiveRecord::Migration[7.2]
  def change
    add_index :cart_items, :session_id
  end
end

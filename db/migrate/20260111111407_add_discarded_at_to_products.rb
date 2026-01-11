class AddDiscardedAtToProducts < ActiveRecord::Migration[7.2]
  def change
    add_column :products, :discarded_at, :datetime
    add_index :products, :discarded_at
  end
end

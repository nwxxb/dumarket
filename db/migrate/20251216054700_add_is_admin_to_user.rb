class AddIsAdminToUser < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :is_admin, :boolean, null: false, default: false
  end
end

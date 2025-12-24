class CreateProducts < ActiveRecord::Migration[7.2]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.text :description, null: false, default: ""
      t.monetize :price

      t.timestamps
    end
  end
end

class CreateClients < ActiveRecord::Migration[6.0]
  def change
    create_table :mozilla_gcm_clients do |t|
      t.string :name, null: false
      t.string :namespace, null: false
      t.integer :category_id, null: false
      t.string :key
    end
  end
end

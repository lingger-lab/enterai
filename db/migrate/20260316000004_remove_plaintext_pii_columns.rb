class RemovePlaintextPiiColumns < ActiveRecord::Migration[8.0]
  def up
    remove_column :reservations, :name
    remove_column :reservations, :phone
    remove_column :reservations, :email
    remove_index :reservations, :email, if_exists: true
  end

  def down
    add_column :reservations, :name, :string
    add_column :reservations, :phone, :string
    add_column :reservations, :email, :string
    add_index :reservations, :email
  end
end

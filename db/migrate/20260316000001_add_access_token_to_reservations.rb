class AddAccessTokenToReservations < ActiveRecord::Migration[8.0]
  def change
    add_column :reservations, :access_token, :string
    add_index :reservations, :access_token, unique: true
  end
end

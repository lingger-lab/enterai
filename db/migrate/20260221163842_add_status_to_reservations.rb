class AddStatusToReservations < ActiveRecord::Migration[8.0]
  def change
    add_column :reservations, :status, :string, default: "pending", null: false, comment: "예약 상태"
    add_index :reservations, :status
  end
end

class AddServiceTypeToReservations < ActiveRecord::Migration[8.0]
  def change
    add_column :reservations, :service_type, :string, default: "coaching"
  end
end

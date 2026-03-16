class AddPackageToReservations < ActiveRecord::Migration[8.0]
  def change
    add_column :reservations, :package, :string, default: "standard", null: false, comment: "선택 패키지"
    add_index :reservations, :package
  end
end

class CreateTimeSlots < ActiveRecord::Migration[8.0]
  def change
    create_table :time_slots do |t|
      t.date :date, null: false
      t.time :start_time, null: false
      t.time :end_time, null: false
      t.string :coaching_type, null: false
      t.string :status, null: false, default: "available"

      t.timestamps
    end

    add_index :time_slots, [:date, :start_time, :coaching_type], unique: true, name: "idx_time_slots_unique"
    add_index :time_slots, [:date, :status], name: "idx_time_slots_date_status"

    add_reference :reservations, :time_slot, null: true, foreign_key: true
  end
end

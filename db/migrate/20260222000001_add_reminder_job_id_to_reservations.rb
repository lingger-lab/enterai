class AddReminderJobIdToReservations < ActiveRecord::Migration[8.0]
  def change
    add_column :reservations, :reminder_job_id, :string
  end
end

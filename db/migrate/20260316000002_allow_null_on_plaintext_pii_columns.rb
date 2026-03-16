class AllowNullOnPlaintextPiiColumns < ActiveRecord::Migration[8.0]
  def change
    change_column_null :reservations, :name, true
    change_column_null :reservations, :phone, true
    change_column_null :reservations, :email, true
  end
end

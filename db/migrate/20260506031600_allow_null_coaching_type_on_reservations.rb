class AllowNullCoachingTypeOnReservations < ActiveRecord::Migration[8.0]
  # app_development 서비스는 coaching_type이 불필요하므로 NULL 허용
  def change
    change_column_null :reservations, :coaching_type, true
  end
end

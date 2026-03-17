# 관리자 계정 생성
admin_email = ENV.fetch("ADMIN_EMAIL", "admin@enterlab.com")
admin_password = ENV.fetch("ADMIN_PASSWORD", "password123")

admin = AdminUser.find_or_initialize_by(email: admin_email)
admin.password = admin_password
admin.password_confirmation = admin_password
admin.save!

puts "관리자 계정 생성 완료: #{admin_email}"

# 시간 슬롯 생성 (기존 슬롯이 없을 때만)
if TimeSlot.count == 0
  start_date = Date.current + 1.day
  end_date = start_date + 28.days

  Reservation::COACHING_TYPES.each do |type|
    count = TimeSlot.bulk_create(
      start_date: start_date,
      end_date: end_date,
      weekdays: [0, 1, 2, 3, 4, 5, 6],
      start_hour: 10,
      end_hour: 18,
      interval_minutes: 60,
      coaching_type: type
    )
    puts "슬롯 생성: #{type} #{count}개"
  end

  puts "총 슬롯: #{TimeSlot.available.future.count}개"
else
  puts "슬롯 이미 존재: #{TimeSlot.count}개 (스킵)"
end

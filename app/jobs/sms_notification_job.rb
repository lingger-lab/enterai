class SmsNotificationJob < ApplicationJob
  queue_as :default
  
  def perform(reservation_id)
    reservation = Reservation.find(reservation_id)
    
    # Naver Cloud SENS를 사용한 SMS 발송
    # attr_encrypted가 자동으로 복호화하므로 직접 사용
    phone = reservation.phone
    content = sms_message(reservation)
    
    SensSmsService.send_sms(phone, content)
  rescue => e
    Rails.logger.error "SMS 발송 실패: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    # 에러 발생 시 재시도 로직 추가 가능
    raise e
  end
  
  private
  
  def sms_message(reservation)
    <<~MESSAGE
      [Enter.ai] 예약이 완료되었습니다!
      
      예약 일시: #{reservation.reservation_datetime.strftime("%Y년 %m월 %d일 %H시 %M분")}
      코칭 형태: #{reservation.coaching_type}
      
      예약 일시 24시간 전에 리마인더를 발송해드립니다.
      문의사항: #{ENV.fetch("CONTACT_PHONE", "050-0000-0000")}
    MESSAGE
  end
end


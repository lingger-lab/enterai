class SmsNotificationJob < ApplicationJob
  queue_as :default

  def perform(reservation_id, notification_type = "created")
    reservation = Reservation.find(reservation_id)

    phone = reservation.phone
    content = sms_message(reservation, notification_type)

    SensSmsService.send_sms(phone, content)
  rescue => e
    Rails.logger.error "SMS 발송 실패 (#{notification_type}): #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    # API 키 미설정으로 인한 실패는 재시도하지 않음
    raise e unless e.message.include?("SENS API")

  end

  private

  def sms_message(reservation, type)
    datetime = reservation.reservation_datetime.strftime("%Y년 %m월 %d일 %H시 %M분")
    contact = ENV.fetch("CONTACT_PHONE", "0502-1927-1910")

    case type
    when "created"
      <<~MSG
        [EnterLab] 예약이 완료되었습니다!

        예약 일시: #{datetime}
        코칭 형태: #{reservation.coaching_type}

        예약 일시 24시간 전에 리마인더를 발송해드립니다.
        문의사항: #{contact}
      MSG
    when "schedule_changed"
      <<~MSG
        [EnterLab] 예약 일정이 변경되었습니다.

        변경된 일시: #{datetime}
        코칭 형태: #{reservation.coaching_type}

        문의사항: #{contact}
      MSG
    when "confirmed"
      <<~MSG
        [EnterLab] 예약이 확정되었습니다.

        확정 일시: #{datetime}
        코칭 형태: #{reservation.coaching_type}

        문의사항: #{contact}
      MSG
    when "cancelled"
      <<~MSG
        [EnterLab] 예약이 취소되었습니다.

        취소된 일시: #{datetime}

        문의사항: #{contact}
      MSG
    when "reminder"
      <<~MSG
        [EnterLab] 내일 예약이 있습니다!

        예약 일시: #{datetime}
        코칭 형태: #{reservation.coaching_type}

        문의사항: #{contact}
      MSG
    when "manual"
      <<~MSG
        [EnterLab] 안내 메시지

        예약 일시: #{datetime}
        코칭 형태: #{reservation.coaching_type}

        문의사항: #{contact}
      MSG
    else
      <<~MSG
        [EnterLab] 알림

        예약 일시: #{datetime}

        문의사항: #{contact}
      MSG
    end
  end
end


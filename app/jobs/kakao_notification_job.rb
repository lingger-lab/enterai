class KakaoNotificationJob < ApplicationJob
  queue_as :default

  TEMPLATE_MAP = {
    "created" => "reservation_created",
    "confirmed" => "reservation_confirmed",
    "cancelled" => "reservation_cancelled",
    "schedule_changed" => "schedule_changed",
    "reminder" => "reminder"
  }.freeze

  def perform(reservation_id, notification_type = "created")
    reservation = Reservation.find(reservation_id)
    template_code = TEMPLATE_MAP[notification_type]
    return unless template_code

    template_args = build_template_args(reservation, notification_type)
    KakaoAlimtalkService.send_message(reservation.phone, template_code, template_args)
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "카카오 알림톡 실패: 예약 #{reservation_id} 없음"
  rescue => e
    Rails.logger.error "카카오 알림톡 실패 (#{notification_type}): #{e.class}"
    raise e
  end

  private

  def build_template_args(reservation, type)
    {
      customer_name: reservation.name,
      datetime: reservation.reservation_datetime.strftime("%Y년 %m월 %d일 %H시 %M분"),
      coaching_type: reservation.coaching_type,
      package: reservation.package_label,
      contact: ENV.fetch("CONTACT_PHONE", "0502-1927-1910"),
      notification_type: type
    }
  end
end

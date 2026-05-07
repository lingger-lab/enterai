# PIPA 권장: 보관 목적 달성 후 개인정보 파기
# 실행: 매일 1회 (Sidekiq cron 또는 외부 스케줄러)
#
# 정책:
# - cancelled: 취소 후 90일 경과 시 삭제
# - completed: 완료 후 1년 경과 시 익명화 (PII 제거, 통계 보존)
class PurgeOldReservationsJob < ApplicationJob
  queue_as :default

  def perform
    purge_cancelled
    anonymize_completed
  end

  private

  def purge_cancelled
    cutoff = 90.days.ago
    scope = Reservation.where(status: "cancelled").where("updated_at < ?", cutoff)
    count = scope.count
    return if count.zero?

    Rails.logger.info "[PIPA] cancelled 예약 #{count}건 삭제 (cutoff: #{cutoff})"
    scope.find_each(&:destroy)
  end

  def anonymize_completed
    cutoff = 1.year.ago
    scope = Reservation.where(status: "completed").where("updated_at < ?", cutoff)
    scope.where.not(encrypted_name: nil).find_each do |reservation|
      Rails.logger.info "[PIPA] 완료 예약 #{reservation.id} 익명화"
      reservation.update_columns(
        encrypted_name: nil, encrypted_name_iv: nil,
        encrypted_phone: nil, encrypted_phone_iv: nil,
        encrypted_email: nil, encrypted_email_iv: nil
      )
    end
  end
end

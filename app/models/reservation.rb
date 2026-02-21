class Reservation < ApplicationRecord
  # 개인정보 암호화 설정
  # ENV['ENCRYPTION_KEY']가 없으면 기본값 사용 (개발/테스트용)
  ENCRYPTION_KEY = ENV['ENCRYPTION_KEY'] || Rails.application.credentials.secret_key_base&.first(32) || '12345678901234567890123456789012'

  attr_encrypted :name, key: ENCRYPTION_KEY
  attr_encrypted :phone, key: ENCRYPTION_KEY
  attr_encrypted :email, key: ENCRYPTION_KEY
  
  # 유효성 검사 (암호화 전 원본 데이터 검증)
  validates :name, presence: true, length: { maximum: 100 }
  validates :phone, presence: true, format: { with: /\A\d{10,11}\z/, message: "올바른 전화번호 형식이 아닙니다" }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :reservation_datetime, presence: true
  validates :coaching_type, presence: true
  validates :privacy_agreed, acceptance: { message: "개인정보 동의는 필수입니다" }
  
  # 콜백: 예약 생성 후 알림 발송 + 리마인더 스케줄링
  after_create_commit :send_notifications
  after_create_commit :schedule_reminder
  after_update_commit :reschedule_reminder, if: :saved_change_to_reservation_datetime?
  
  # 예약 상태
  STATUSES = %w[pending confirmed cancelled completed].freeze

  validates :status, inclusion: { in: STATUSES }

  # 코칭 형태 옵션 (PRD에 따라 출장/사무실로 변경)
  COACHING_TYPES = [
    "출장 코칭",
    "사무실 코칭",
    "온라인 코칭"
  ].freeze

  # 선택 과목 옵션
  SUBJECT_OPTIONS = [
    "AI 기초 이해",
    "AI 도구 활용",
    "콘텐츠 제작",
    "마케팅 자동화",
    "수익화 전략"
  ].freeze

  # 상태 한글 표시
  STATUS_LABELS = {
    "pending" => "대기중",
    "confirmed" => "확정",
    "cancelled" => "취소",
    "completed" => "완료"
  }.freeze

  def status_label
    STATUS_LABELS[status] || status
  end

  private

  # 알림 발송 메서드 (SMS + 이메일)
  def send_notifications
    SmsNotificationJob.perform_later(self.id, "created")
    EmailNotificationJob.perform_later(self.id, "created")
  end

  # 24시간 전 리마인더 스케줄링
  def schedule_reminder
    reminder_time = reservation_datetime - 24.hours
    return if reminder_time <= Time.current

    job = ReminderNotificationJob.set(wait_until: reminder_time).perform_later(self.id)
    update_column(:reminder_job_id, job.provider_job_id) if job.respond_to?(:provider_job_id)
  end

  # 일정 변경 시 리마인더 재스케줄링
  def reschedule_reminder
    cancel_scheduled_reminder
    schedule_reminder
  end

  # 기존 스케줄된 리마인더 취소
  def cancel_scheduled_reminder
    return unless reminder_job_id.present?

    scheduled_set = Sidekiq::ScheduledSet.new
    job = scheduled_set.find_job(reminder_job_id)
    job&.delete
    update_column(:reminder_job_id, nil)
  rescue => e
    Rails.logger.warn "리마인더 취소 실패: #{e.message}"
  end
end


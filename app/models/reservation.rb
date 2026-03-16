class Reservation < ApplicationRecord
  # 개인정보 암호화 (attr_encrypted)
  ENCRYPTION_KEY = ENV.fetch("ENCRYPTION_KEY") { Rails.env.production? ? raise("ENCRYPTION_KEY must be set in production") : "dev_fallback_key_0123456789abcdef" }

  attr_encrypted :name, key: ENCRYPTION_KEY
  attr_encrypted :phone, key: ENCRYPTION_KEY
  attr_encrypted :email, key: ENCRYPTION_KEY

  # 상수 정의 (validates에서 참조하므로 먼저 선언)
  STATUSES = %w[pending confirmed cancelled completed].freeze

  COACHING_TYPES = [
    "출장 코칭",
    "사무실 코칭",
    "온라인 코칭"
  ].freeze

  SUBJECT_OPTIONS = [
    "AI 기초 이해",
    "AI 도구 활용",
    "콘텐츠 제작",
    "마케팅 자동화",
    "수익화 전략"
  ].freeze

  PACKAGES = {
    "starter" => {
      name: "STARTER",
      price: 490_000,
      label: "AI 체험 코스",
      duration: "2주 (4시간)",
      features: ["1:1 코칭 4시간", "MVP 프로토타입 1개", "1개월 Q&A", "3개월 커뮤니티"]
    },
    "standard" => {
      name: "STANDARD",
      price: 800_000,
      label: "AI 수익화 코스",
      duration: "4주 (8시간)",
      features: ["1:1 코칭 8시간", "완성형 앱 1개 + 배포", "3개월 Q&A", "1년 커뮤니티", "AI 도구 템플릿"]
    },
    "premium" => {
      name: "PREMIUM",
      price: 1_200_000,
      label: "AI 창업 코스",
      duration: "6주 (12시간)",
      features: ["1:1 코칭 12시간", "앱 + 수익화 전략", "6개월 Q&A", "1년 VIP 커뮤니티", "AI 도구 템플릿 + 전자책", "월 1회 화상 멘토링"]
    }
  }.freeze

  STATUS_LABELS = {
    "pending" => "대기중",
    "confirmed" => "확정",
    "cancelled" => "취소",
    "completed" => "완료"
  }.freeze

  VALID_TRANSITIONS = {
    "pending" => %w[confirmed cancelled],
    "confirmed" => %w[cancelled completed],
    "cancelled" => %w[pending],
    "completed" => []
  }.freeze

  # 유효성 검사
  validates :name, presence: true, length: { maximum: 100 }
  validates :phone, presence: true, format: { with: /\A[\d\-]{10,13}\z/, message: "올바른 전화번호 형식이 아닙니다" }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :reservation_datetime, presence: true
  validates :coaching_type, presence: true, inclusion: { in: COACHING_TYPES }
  validates :requests, length: { maximum: 2000 }
  validates :privacy_agreed, acceptance: { message: "개인정보 동의는 필수입니다" }
  validates :status, inclusion: { in: STATUSES }
  validates :package, inclusion: { in: PACKAGES.keys }
  validate :validate_selected_subjects

  # 콜백
  before_create :generate_access_token
  after_create_commit :send_notifications
  after_create_commit :schedule_reminder
  after_update_commit :reschedule_reminder, if: :saved_change_to_reservation_datetime?

  def status_label
    STATUS_LABELS[status] || status
  end

  def package_info
    PACKAGES[package]
  end

  def package_label
    PACKAGES.dig(package, :name) || package
  end

  def can_transition_to?(new_status)
    VALID_TRANSITIONS.fetch(status, []).include?(new_status)
  end

  private

  def generate_access_token
    self.access_token = SecureRandom.urlsafe_base64(32)
  end

  def validate_selected_subjects
    return if selected_subjects.blank?
    invalid = selected_subjects - SUBJECT_OPTIONS
    errors.add(:selected_subjects, "유효하지 않은 과목이 포함되어 있습니다") if invalid.any?
  end

  def send_notifications
    SmsNotificationJob.perform_later(self.id, "created")
    EmailNotificationJob.perform_later(self.id, "created")
  end

  def schedule_reminder
    reminder_time = reservation_datetime - 24.hours
    return if reminder_time <= Time.current

    job = ReminderNotificationJob.set(wait_until: reminder_time).perform_later(self.id)
    update_column(:reminder_job_id, job.provider_job_id) if job.respond_to?(:provider_job_id)
  end

  def reschedule_reminder
    cancel_scheduled_reminder
    schedule_reminder
  end

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

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
      price: 980_000,
      label: "AI 체험 코스",
      duration: "2주 (4시간)",
      features: ["1:1 코칭 4시간", "MVP 프로토타입 1개", "온라인 1:1 코칭 지원(30분/일, 2.5시간/주, 10시간/월)", "3개월 카톡 채팅 커뮤니티", "수강자 요청에 따라 AI활용등으로 커리큘럼 조정 가능"]
    },
    "standard" => {
      name: "STANDARD",
      price: 1_480_000,
      label: "AI 수익화 코스",
      duration: "4주 (8시간)",
      features: ["1:1 코칭 8시간", "완성형 앱 1개 + 배포", "온라인 1:1 코칭 지원(30분/일, 2.5시간/주, 10시간/월)", "1년 카톡 채팅 커뮤니티", "AI 도구 템플릿", "수강자 요청에 따라 AI활용등으로 커리큘럼 조정 가능"]
    },
    "premium" => {
      name: "PREMIUM",
      price: 2_490_000,
      label: "AI 창업 코스",
      duration: "6주 (12시간)",
      features: ["1:1 코칭 12시간", "앱 + 수익화 전략", "온라인 1:1 코칭 지원(30분/일, 2.5시간/주, 10시간/월)", "1년 VIP 카톡 채팅 커뮤니티", "AI 도구 템플릿 + 전자책", "월 1회 화상 멘토링", "수강자 요청에 따라 AI활용등으로 커리큘럼 조정 가능"]
    }
  }.freeze

  APP_DEV_PACKAGES = {
    "basic" => {
      name: "BASIC",
      price: 2_900_000,
      label: "MVP·프로토타입 구축",
      duration: "2~4주",
      features: ["PRD 작성 및 비즈니스 로직 설계", "기본 UI/UX 프론트엔드 구성", "Cloud SQL 연동 DB (CRUD)", "동작하는 프로토타입 제공"]
    },
    "standard_dev" => {
      name: "STANDARD",
      price: 5_000_000,
      label: "상용 서비스 런칭·수익화",
      duration: "4~8주",
      features: ["UX 중심 프로덕트 고도화", "외부 API 연동 (MCP)", "결제 시스템 + 소셜 로그인", "Vercel/GCP 배포 + 관리자 대시보드"]
    },
    "premium_dev" => {
      name: "PREMIUM",
      price: 10_000_000,
      label: "완전 자동화 시스템",
      duration: "8~12주",
      features: ["다중 AI 에이전트 대규모 개발", "챗봇 + 마케팅 자동화", "실시간 매출 데이터 시각화", "AI 기반 PMF 분석 리포트"]
    }
  }.freeze

  SERVICE_TYPES = %w[coaching app_development].freeze

  # service_type은 폼에서만 사용 (DB 컬럼 불필요)
  attr_accessor :service_type

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

  # 연관
  belongs_to :time_slot, optional: true
  belongs_to :user, optional: true
  has_one :review
  has_many :payments, dependent: :destroy

  # 유효성 검사
  validates :name, presence: true, length: { maximum: 100 }
  validates :phone, presence: true, format: { with: /\A[\d\-]{10,13}\z/, message: "올바른 전화번호 형식이 아닙니다" }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :reservation_datetime, presence: true
  validates :coaching_type, presence: true, inclusion: { in: COACHING_TYPES },
            unless: -> { service_type == "app_development" }
  validates :requests, length: { maximum: 2000 }
  validates :privacy_agreed, acceptance: { message: "개인정보 동의는 필수입니다" }
  validates :status, inclusion: { in: STATUSES }
  validates :package, inclusion: { in: PACKAGES.keys + APP_DEV_PACKAGES.keys }
  validates :service_type, inclusion: { in: SERVICE_TYPES }, allow_nil: true
  validate :validate_selected_subjects

  # 콜백
  before_create :generate_access_token
  after_create_commit :send_notifications
  after_create_commit :mark_slot_booked
  after_create_commit :schedule_reminder
  after_update_commit :reschedule_reminder, if: :saved_change_to_reservation_datetime?
  after_update_commit :release_slot_on_cancel, if: -> { saved_change_to_status? && status == "cancelled" }
  after_update_commit :send_review_request, if: -> { saved_change_to_status? && status == "completed" }

  def status_label
    STATUS_LABELS[status] || status
  end

  def package_info
    PACKAGES[package] || APP_DEV_PACKAGES[package]
  end

  def package_label
    PACKAGES.dig(package, :name) || APP_DEV_PACKAGES.dig(package, :name) || package
  end

  def app_development?
    service_type == "app_development"
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

  def mark_slot_booked
    time_slot&.book!
  end

  def release_slot_on_cancel
    time_slot&.release!
  end

  def send_review_request
    return if review.present?
    create_review!
    EmailNotificationJob.perform_later(self.id, "review_request")
  end

  def send_notifications
    SmsNotificationJob.perform_later(self.id, "created")
    EmailNotificationJob.perform_later(self.id, "created")
    KakaoNotificationJob.perform_later(self.id, "created")
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

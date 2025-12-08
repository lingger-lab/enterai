class Reservation < ApplicationRecord
  # 개인정보 암호화 설정
  attr_encrypted :name, key: ENV.fetch('ENCRYPTION_KEY', Rails.application.credentials.secret_key_base[0..31])
  attr_encrypted :phone, key: ENV.fetch('ENCRYPTION_KEY', Rails.application.credentials.secret_key_base[0..31])
  attr_encrypted :email, key: ENV.fetch('ENCRYPTION_KEY', Rails.application.credentials.secret_key_base[0..31])
  
  # 유효성 검사 (암호화 전 원본 데이터 검증)
  validates :name, presence: true, length: { maximum: 100 }
  validates :phone, presence: true, format: { with: /\A\d{10,11}\z/, message: "올바른 전화번호 형식이 아닙니다" }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :reservation_datetime, presence: true
  validates :coaching_type, presence: true
  validates :privacy_agreed, acceptance: { message: "개인정보 동의는 필수입니다" }
  
  # 콜백: 예약 생성 후 알림 발송
  after_create_commit :send_notifications
  
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
  
  private
  
  # 알림 발송 메서드
  def send_notifications
    # 이메일 발송 (비동기)
    ReservationMailer.confirmation(self).deliver_later
    ReservationMailer.admin_notification(self).deliver_later
    
    # SMS 발송 (비동기) - Naver Cloud SENS 사용
    SmsNotificationJob.perform_later(self.id)
  end
  
  # 암호화된 데이터 복호화 헬퍼 메서드
  def decrypted_name
    name # attr_encrypted가 자동으로 복호화
  end
  
  def decrypted_phone
    phone # attr_encrypted가 자동으로 복호화
  end
  
  def decrypted_email
    email # attr_encrypted가 자동으로 복호화
  end
end


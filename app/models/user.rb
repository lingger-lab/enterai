# 수강생 사용자 (관리자 AdminUser와 분리)
#
# 스캐폴드 상태:
# - Devise database_authenticatable + recoverable + rememberable 활성
# - OmniAuth(카카오) adapter 코드 작성됨, 환경변수(AUTH_PROVIDER=kakao) 시에만 활성
# - 현재 토큰 기반 예약과 병행 가능 (Reservation.user_id 는 nullable)
#
# 향후 활성화:
#   1) Gemfile에 omniauth-kakao 추가 후 bundle install
#   2) Devise routes 활성화 (config/routes.rb)
#   3) Kakao Developers 앱 등록 + 환경변수
class User < ApplicationRecord
  ENCRYPTION_KEY = ENV.fetch("ENCRYPTION_KEY") {
    Rails.env.production? ? raise("ENCRYPTION_KEY must be set in production") : "dev_fallback_key_0123456789abcdef"
  }

  # PII 암호화 (Reservation과 동일 패턴)
  attr_encrypted :name, key: ENCRYPTION_KEY
  attr_encrypted :phone, key: ENCRYPTION_KEY

  # Devise (database_authenticatable + recoverable + rememberable + omniauthable)
  devise :database_authenticatable, :recoverable, :rememberable

  has_many :reservations, dependent: :nullify

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  # OAuth provider로 가입한 경우 (이메일/비밀번호 가입은 provider/uid 모두 nil)
  scope :oauth_users, -> { where.not(provider: nil) }
  scope :email_users, -> { where(provider: nil) }

  # OmniAuth callback 처리 (활성화 시 사용)
  # def self.from_omniauth(auth)
  #   where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
  #     user.email = auth.info.email
  #     user.password = Devise.friendly_token[0, 20]
  #     user.name = auth.info.name
  #   end
  # end

  def display_name
    name.presence || email.split("@").first
  end

  def grant_marketing_consent!
    update!(marketing_agreed: true, marketing_agreed_at: Time.current)
  end

  def revoke_marketing_consent!
    update!(marketing_agreed: false, marketing_agreed_at: nil)
  end
end

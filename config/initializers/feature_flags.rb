# 기능 플래그 (Feature Flags)
#
# 모든 신규 기능은 default off. 환경변수로 활성화.
# 사용: FeatureFlags.billing_enabled?, FeatureFlags.auth_provider
module FeatureFlags
  module_function

  # 결제
  # BILLING_PROVIDER=none | toss | kakaopay
  def billing_provider
    ENV.fetch("BILLING_PROVIDER", "none").downcase
  end

  def billing_enabled?
    billing_provider != "none"
  end

  # 회원 인증
  # AUTH_PROVIDER=token | kakao | email
  def auth_provider
    ENV.fetch("AUTH_PROVIDER", "token").downcase
  end

  def kakao_oauth_enabled?
    auth_provider == "kakao" && ENV["KAKAO_CLIENT_ID"].present?
  end

  def email_auth_enabled?
    auth_provider == "email"
  end

  # 카카오 알림톡
  def kakao_alimtalk_enabled?
    ENV["KAKAO_ALIMTALK_KEY"].present?
  end

  # 외부 에러 모니터링
  def sentry_enabled?
    ENV["SENTRY_DSN"].present?
  end
end

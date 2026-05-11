module Billing
  # 토스페이먼츠 v2 adapter (스캐폴드)
  #
  # 활성화 절차:
  # 1) 토스페이먼츠 가입 + 사업자 인증 + API Key 발급
  # 2) 환경변수 설정:
  #    BILLING_PROVIDER=toss
  #    TOSS_CLIENT_KEY=test_ck_... (또는 live_ck_...)
  #    TOSS_SECRET_KEY=test_sk_... (또는 live_sk_...)
  #    TOSS_WEBHOOK_SECRET=...
  # 3) Cloud Run 재배포
  # 4) 관리자 페이지에서 "결제링크 발송" 버튼 활성화 확인
  #
  # 참고: https://docs.tosspayments.com/reference
  class TossAdapter < BaseAdapter
    API_BASE = "https://api.tosspayments.com/v1"

    def enabled?
      ENV["TOSS_SECRET_KEY"].present?
    end

    def issue_payment_link(payment)
      ensure_enabled!

      # TODO: 실제 활성화 시 구현
      # 1) order_id 생성: "EL-#{payment.id}-#{SecureRandom.hex(4)}"
      # 2) POST #{API_BASE}/payments — payment_url 반환
      # 3) payment.update!(pg_order_id: order_id, status: "issued", issued_at: Time.current)
      # 4) return { payment_url: ..., order_id: order_id }
      raise NotImplementedError, "Toss 결제링크 발급은 활성화 후 구현 필요"
    end

    def handle_webhook(payload, signature: nil)
      ensure_enabled!
      verify_signature!(payload, signature)

      # TODO: 활성화 시 구현
      # paymentKey, orderId, status 파싱
      # Payment 찾아서 mark_paid! / mark_failed!
      raise NotImplementedError, "Toss 웹훅 처리는 활성화 후 구현 필요"
    end

    def refund(payment, amount: nil)
      ensure_enabled!
      raise NotImplementedError, "Toss 환불은 활성화 후 구현 필요"
    end

    private

    def ensure_enabled!
      raise DisabledError, "TOSS_SECRET_KEY 미설정" unless enabled?
    end

    def verify_signature!(payload, signature)
      return if signature.blank? && ENV["TOSS_WEBHOOK_SECRET"].blank?
      # TODO: HMAC-SHA256 검증
    end

    def auth_header
      "Basic " + Base64.strict_encode64("#{ENV['TOSS_SECRET_KEY']}:")
    end
  end
end

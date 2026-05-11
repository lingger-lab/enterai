module Billing
  # 결제 PG adapter 추상 클래스
  # 구체 구현: Billing::TossAdapter, Billing::KakaoPayAdapter 등
  class BaseAdapter
    DisabledError = Class.new(StandardError)
    APIError = Class.new(StandardError)

    # 결제 링크 발급 (PG에 결제 준비 요청)
    # Returns: { payment_url: "...", order_id: "..." }
    def issue_payment_link(payment)
      raise NotImplementedError
    end

    # 웹훅 처리 (PG에서 결제 결과 콜백)
    # Returns: { status: "paid", payment_key: "..." }
    def handle_webhook(payload, signature: nil)
      raise NotImplementedError
    end

    # 환불 요청
    def refund(payment, amount: nil)
      raise NotImplementedError
    end

    # 활성화 여부
    def enabled?
      false
    end
  end

  # 비활성화된 adapter (default)
  class NoneAdapter < BaseAdapter
    def issue_payment_link(_payment)
      raise DisabledError, "결제 기능이 비활성화 상태입니다. BILLING_PROVIDER 환경변수를 설정하세요."
    end

    def handle_webhook(_payload, signature: nil)
      raise DisabledError, "결제 기능 비활성"
    end

    def refund(_payment, amount: nil)
      raise DisabledError, "결제 기능 비활성"
    end
  end

  # 현재 활성화된 adapter 반환
  def self.current
    case FeatureFlags.billing_provider
    when "toss" then TossAdapter.new
    when "kakaopay" then NoneAdapter.new # 향후 구현
    else NoneAdapter.new
    end
  end
end

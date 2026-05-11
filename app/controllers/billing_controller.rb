# 결제 흐름 처리 (스캐폴드 — BILLING_PROVIDER=none 시 503 응답)
class BillingController < ApplicationController
  before_action :ensure_billing_enabled, except: [:status]

  # POST /billing/issue
  # 관리자가 발급한 결제링크를 사용자가 클릭한 후 처리
  def issue
    payment = Payment.find(params[:payment_id])
    result = Billing.current.issue_payment_link(payment)
    redirect_to result[:payment_url], allow_other_host: true
  rescue Billing::BaseAdapter::DisabledError => e
    render plain: e.message, status: :service_unavailable
  rescue ActiveRecord::RecordNotFound
    render plain: "결제 정보를 찾을 수 없습니다.", status: :not_found
  end

  # POST /billing/webhook
  # PG에서 호출하는 결제 결과 콜백
  def webhook
    signature = request.headers["TossPayments-Signature"] || request.headers["X-Signature"]
    Billing.current.handle_webhook(request.body.read, signature: signature)
    head :ok
  rescue Billing::BaseAdapter::DisabledError
    head :service_unavailable
  rescue Billing::BaseAdapter::APIError => e
    Rails.logger.error "Billing webhook error: #{e.message}"
    head :bad_request
  end

  # GET /billing/status
  # 결제 활성화 상태 확인 (모니터링/디버그용)
  def status
    render json: {
      enabled: FeatureFlags.billing_enabled?,
      provider: FeatureFlags.billing_provider,
      adapter_enabled: Billing.current.enabled?
    }
  end

  private

  def ensure_billing_enabled
    return if FeatureFlags.billing_enabled?

    render plain: "결제 기능이 비활성화 상태입니다.", status: :service_unavailable
  end
end

# 카카오 알림톡 발송 서비스 (프로바이더 미정, stub 구현)
# ENV['KAKAO_ALIMTALK_ENABLED'] = 'true' 설정 시에만 동작
class KakaoAlimtalkService
  class << self
    def send_message(phone, template_code, template_args = {})
      unless enabled?
        Rails.logger.info "카카오 알림톡 스킵: KAKAO_ALIMTALK_ENABLED가 'true'가 아닙니다"
        return nil
      end
      unless configured?
        Rails.logger.warn "카카오 알림톡 스킵: API 키가 설정되지 않았습니다"
        return nil
      end

      send_via_provider(phone, template_code, template_args)
    end

    private

    def enabled?
      ENV["KAKAO_ALIMTALK_ENABLED"] == "true"
    end

    def configured?
      rest_api_key.present? && sender_key.present?
    end

    def rest_api_key  = ENV["KAKAO_REST_API_KEY"]
    def sender_key    = ENV["KAKAO_SENDER_KEY"]

    def send_via_provider(phone, template_code, template_args)
      # 프로바이더 선정 후 구현 (NHN Cloud / Solapi / 카카오 비즈)
      # 현재는 stub: 로그만 남기고 성공 반환
      formatted_phone = phone.gsub(/[-\s]/, "")
      Rails.logger.info "카카오 알림톡 전송 (stub): #{mask_phone(formatted_phone)}, template=#{template_code}"
      { status: "stub", template_code: template_code }
    end

    def mask_phone(phone)
      return phone if phone.length < 7
      phone[0..2] + "*" * (phone.length - 6) + phone[-3..]
    end
  end
end

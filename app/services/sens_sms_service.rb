# Naver Cloud SENS SMS 발송 서비스
require 'rest-client'
require 'json'
require 'base64'
require 'openssl'

class SensSmsService
  class << self
    def send_sms(phone, content)
      unless configured?
        Rails.logger.warn "SMS 발송 스킵: SENS API 키가 설정되지 않았습니다"
        return nil
      end

      formatted_phone = phone.gsub(/[-\s]/, '')

      uri = "/sms/v2/services/#{service_id}/messages"
      url = "https://sens.apigw.ntruss.com" + uri
      timestamp = (Time.now.to_f * 1000).to_i.to_s

      signature = Base64.strict_encode64(
        OpenSSL::HMAC.digest('sha256', secret_key, "POST #{uri}\n#{timestamp}\n#{access_key}")
      )

      headers = {
        'Content-Type': 'application/json; charset=utf-8',
        'x-ncp-apigw-timestamp': timestamp,
        'x-ncp-iam-access-key': access_key,
        'x-ncp-apigw-signature-v2': signature
      }

      body = {
        type: 'SMS',
        contentType: 'COMM',
        countryCode: '82',
        from: sender_number,
        content: content,
        messages: [{ to: formatted_phone }]
      }

      response = RestClient.post(url, body.to_json, headers)
      result = JSON.parse(response.body)

      Rails.logger.info "SMS sent to #{mask_phone(formatted_phone)}: #{result['requestId']}"
      result
    rescue => e
      Rails.logger.error "SMS 발송 실패: #{e.message}"
      raise e
    end

    private

    def configured?
      access_key.present? && secret_key.present? && service_id.present? && sender_number.present?
    end

    def access_key    = ENV['SENS_ACCESS_KEY']
    def secret_key    = ENV['SENS_SECRET_KEY']
    def service_id    = ENV['SENS_SERVICE_ID']
    def sender_number = ENV['SENS_SENDER_NUMBER']

    def mask_phone(phone)
      return phone if phone.length < 7
      phone[0..2] + "*" * (phone.length - 6) + phone[-3..]
    end
  end
end


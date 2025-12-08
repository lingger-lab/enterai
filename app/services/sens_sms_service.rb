# Naver Cloud SENS SMS 발송 서비스
require 'rest-client'
require 'json'
require 'base64'
require 'openssl'

class SensSmsService
  SENS_ACCESS_KEY = ENV['SENS_ACCESS_KEY']
  SENS_SECRET_KEY = ENV['SENS_SECRET_KEY']
  SENS_SERVICE_ID = ENV['SENS_SERVICE_ID']
  SENS_SENDER_NUMBER = ENV['SENS_SENDER_NUMBER']

  # SMS 발송 메서드
  def self.send_sms(phone, content)
    # 전화번호 형식 변환 (010-1234-5678 -> 01012345678)
    formatted_phone = phone.gsub(/[-\s]/, '')
    
    uri = "/sms/v2/services/#{SENS_SERVICE_ID}/messages"
    url = "https://sens.apigw.ntruss.com" + uri
    timestamp = (Time.now.to_f * 1000).to_i.to_s

    # 서명 생성
    signature = Base64.strict_encode64(
      OpenSSL::HMAC.digest('sha256', SENS_SECRET_KEY, "POST #{uri}\n#{timestamp}\n#{SENS_ACCESS_KEY}")
    )

    headers = {
      'Content-Type': 'application/json; charset=utf-8',
      'x-ncp-apigw-timestamp': timestamp,
      'x-ncp-iam-access-key': SENS_ACCESS_KEY,
      'x-ncp-apigw-signature-v2': signature
    }

    body = {
      type: 'SMS',
      contentType: 'COMM',
      countryCode: '82',
      from: SENS_SENDER_NUMBER,
      content: content,
      messages: [{ to: formatted_phone }]
    }

    response = RestClient.post(url, body.to_json, headers)
    result = JSON.parse(response.body)
    
    Rails.logger.info "SMS sent to #{formatted_phone}: #{result['requestId']}"
    result
  rescue => e
    Rails.logger.error "SMS 발송 실패: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end
end


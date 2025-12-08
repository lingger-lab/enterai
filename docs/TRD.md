# [Enter.ai] 기술 사양서 (TRD)

# ⚙ [Enter.ai] 기술 사양서 (TRD.md)

## 🇰🇷 국내망 기반 버전 — (050 가상번호 + Naver Cloud SENS + SendGrid)

### ✅ 프로젝트 개요

한국 내에서만 운영되는 **1인 AI 코칭 예약 플랫폼**으로, Twilio 등의 해외 서비스를 사용하지 않고 **국내망 기반 문자·전화 시스템**으로 구성합니다.

---

### 권장 스택

* **프레임워크:** Ruby on Rails 8.0 (Hotwire 포함)
* **프론트엔드:** TailwindCSS + Turbo (Hotwire)
* **DB:** PostgreSQL
* **이메일 발송:** SendGrid API (무료 플랜)
* **문자 발송:** Naver Cloud SENS (SMS API)
* **전화(가상번호):** KT 050 개인 안심번호 or 콜패스(CallPass)
* **배포:** Vercel (프론트엔드) + Render (Rails 백엔드)
* **AI 관리:** ChatGPT / GitHub Copilot 기반 자동 코드 보정

---

### 선정 이유

* 해외 서비스(Twilio) 의존 없이 **국내망 안정성 확보**.
* Naver Cloud SENS는 한국 통신사 기반으로 문자 발송 지연이 거의 없음.
* KT 050은 저렴하면서도 가상번호 착신 기능을 제공, 개인정보 보호에 유리.
* Rails의 ActionMailer와 SENS REST API를 결합해 자동 알림 시스템 구현이 용이.

---

### 디렉토리 구조 (권장)

```
/enter_ai_app
 ┣ /app
 ┃ ┣ /controllers
 ┃ ┃ ┣ reservations_controller.rb
 ┃ ┣ /models
 ┃ ┃ ┣ reservation.rb
 ┃ ┣ /views
 ┃ ┃ ┣ reservations/
 ┃ ┣ /mailers
 ┃ ┃ ┣ reservation_mailer.rb
 ┃ ┣ /services
 ┃ ┃ ┣ sens_sms_service.rb
 ┣ /config
 ┃ ┣ routes.rb
 ┣ /db
 ┃ ┣ schema.rb
 ┣ Gemfile
```

---

### 필수 라이브러리 및 버전

| 목적      | 라이브러리             | 버전   | 설명                       |
| ------- | ----------------- | ---- | ------------------------ |
| 이메일     | sendgrid-ruby     | ^7.0 | SendGrid API 이메일 발송      |
| 문자      | rest-client       | ^2.1 | Naver Cloud SENS API 호출용 |
| UI      | tailwindcss-rails | ^2.0 | CSS 프레임워크                |
| DB      | pg                | ^1.5 | PostgreSQL 드라이버          |
| 인증(확장용) | devise            | ^4.9 | 로그인/관리자 인증용              |

---

### Naver Cloud SENS 문자 발송 구조

```ruby
# app/services/sens_sms_service.rb
require 'rest-client'
require 'json'
require 'base64'
require 'openssl'

class SensSmsService
  SENS_ACCESS_KEY = ENV['SENS_ACCESS_KEY']
  SENS_SECRET_KEY = ENV['SENS_SECRET_KEY']
  SENS_SERVICE_ID = ENV['SENS_SERVICE_ID']
  SENDER_NUMBER = ENV['SENS_SENDER_NUMBER']

  def self.send_sms(phone, content)
    uri = "/sms/v2/services/#{SENS_SERVICE_ID}/messages"
    url = "https://sens.apigw.ntruss.com" + uri
    timestamp = (Time.now.to_f * 1000).to_i.to_s

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
      from: SENDER_NUMBER,
      content: content,
      messages: [{ to: phone }]
    }

    RestClient.post(url, body.to_json, headers)
  end
end
```

---

### 이메일 발송 (SendGrid)

```ruby
class ReservationMailer < ApplicationMailer
  def confirmation(reservation)
    @reservation = reservation
    mail(to: @reservation.email, subject: 'Enter.ai 예약이 완료되었습니다')
  end
end
```

---

### 예약 생성 시 알림 로직

```ruby
class Reservation < ApplicationRecord
  after_create_commit :send_notifications

  def send_notifications
    ReservationMailer.confirmation(self).deliver_later
    SensSmsService.send_sms(phone, "[Enter.ai] #{@name}님, 예약이 완료되었습니다.")
  end
end
```

---

### 전화(050) 착신 및 고객문의 구분 방식

* 고객은 **050 가상번호**로 전화 → 내 실제 번호로 착신.
* 내 휴대폰에는 항상 050번호로 표시되어 **문의전화 즉시 구분 가능**.
* 예약자 전화번호가 DB에 있으면 **예약자 이름 Whisper 안내 (선택 구현 가능)**.

---

### AI 코딩 주의사항

* `Turbo` 기반 폼을 사용하여 JS 의존 최소화.
* `deliver_later`로 이메일 비동기 처리.
* `SensSmsService`는 REST API 방식으로 즉시 호출.
* 예약자 전화번호는 암호화 저장.
* 개인정보 보호법을 준수해 DB 접근 제한.

---

### 🇰🇷 요약 — 국내망 기술 조합

| 구성요소 | 기술 / 서비스          | 설명                   |
| ---- | ----------------- | -------------------- |
| 전화   | KT 050 / 콜패스      | 가상번호 착신, 번호 노출 방지    |
| 문자   | Naver Cloud SENS  | API 기반 예약확인 / 알림 SMS |
| 이메일  | SendGrid          | 예약완료 메일 자동 발송        |
| 웹    | Rails 8 + Hotwire | 예약 폼 / DB / 자동화 중심   |
| 배포   | Vercel + Render   | 프론트·백 분리형 배포         |

---

✅ 이 버전은 Twilio Whisper 로직을 대체하며, 100% 국내 서비스 기반으로 안정적입니다.
✅ Cursor AI는 이 문서 기반으로 Rails 프로젝트를 생성하면 됩니다.

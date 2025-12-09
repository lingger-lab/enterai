# EnterLab - AI 코칭 예약 시스템

Ruby on Rails 8.0 기반의 AI 코칭 예약 및 자동 알림 웹서비스입니다.

## 주요 기능

- 1:1 코칭 예약 폼 (이름, 연락처, 이메일, 날짜/시간, 코칭형태, 선택과목, 요청사항, 개인정보동의)
- 예약 제출 시 DB 저장 후 자동 알림 발송
  - 사용자: 예약완료 이메일 및 SMS
  - 관리자: 신규예약 알림 이메일
- SendGrid API를 통한 이메일 발송
- Twilio Ruby SDK를 통한 SMS 발송
- ActionMailer 및 ActiveJob을 사용한 비동기 발송
- Tailwind CSS 기반 UI
- Hotwire (Turbo) 기반 폼 제출 애니메이션

## 기술 스택

- Ruby on Rails 8.0
- PostgreSQL
- Tailwind CSS
- Hotwire (Turbo + Stimulus)
- SendGrid API
- Twilio Ruby SDK
- Sidekiq (비동기 작업 처리)

## 설치 방법

### 1. Ruby 및 Rails 설치

```bash
# Ruby 3.3.0 설치 (rbenv 또는 rvm 사용)
ruby --version  # 3.3.0 확인

# Rails 8.0 설치
gem install rails -v 8.0.0
```

### 2. 의존성 설치

```bash
# Gem 설치
bundle install

# Node.js 패키지 설치 (Tailwind CSS)
npm install
```

### 3. 데이터베이스 설정

```bash
# PostgreSQL 데이터베이스 생성
rails db:create

# 마이그레이션 실행
rails db:migrate
```

### 4. 환경 변수 설정

`.env` 파일을 생성하고 다음 변수들을 설정하세요:

```env
# 데이터베이스
DATABASE_USER=postgres
DATABASE_PASSWORD=your_password
DATABASE_HOST=localhost

# SendGrid
SENDGRID_API_KEY=your_sendgrid_api_key
SENDGRID_FROM_EMAIL=noreply@enterlab.com
SENDGRID_DOMAIN=enterlab.com

# Twilio
TWILIO_ACCOUNT_SID=your_twilio_account_sid
TWILIO_AUTH_TOKEN=your_twilio_auth_token
TWILIO_PHONE_NUMBER=+1234567890

# 관리자 이메일
ADMIN_EMAIL=admin@enterlab.com

# 연락처
CONTACT_PHONE=02-1234-5678

# 호스트 (프로덕션)
HOST=enterlab.com
```

### 5. 서버 실행

```bash
# 개발 서버 시작
rails server

# 또는
rails s
```

브라우저에서 `http://localhost:3000` 접속

## 프로젝트 구조

```
/app
  /controllers
    - application_controller.rb
    - reservations_controller.rb
  /models
    - reservation.rb
  /views
    /reservations
      - new.html.erb
      - show.html.erb
      - create.turbo_stream.erb
    /reservation_mailer
      - confirmation.html.erb
      - confirmation.text.erb
      - admin_notification.html.erb
      - admin_notification.text.erb
    /layouts
      - application.html.erb
  /mailers
    - application_mailer.rb
    - reservation_mailer.rb
  /jobs
    - sms_notification_job.rb
  /assets
    /stylesheets
      - application.tailwind.css
  /javascript
    /controllers
      - application.js
      - index.js
    - application.js
/config
  - application.rb
  - routes.rb
  - database.yml
  - tailwind.config.js
  /environments
    - development.rb
    - production.rb
    - test.rb
  /initializers
    - sendgrid.rb
    - twilio.rb
/db
  /migrate
    - 20240101000001_create_reservations.rb
```

## 주요 파일 설명

### 모델 (app/models/reservation.rb)
- 예약 정보를 저장하는 모델
- 유효성 검사 및 콜백 처리
- 예약 생성 시 자동으로 알림 발송

### 컨트롤러 (app/controllers/reservations_controller.rb)
- 예약 폼 표시 및 제출 처리
- Turbo Stream을 사용한 비동기 폼 처리

### 메일러 (app/mailers/reservation_mailer.rb)
- 사용자 예약 확인 이메일
- 관리자 신규 예약 알림 이메일

### Job (app/jobs/sms_notification_job.rb)
- Twilio를 사용한 SMS 발송
- ActiveJob을 통한 비동기 처리

## 배포

### Vercel (프론트엔드) + Render (Rails API)

1. Render에 Rails API 배포
2. Vercel에 프론트엔드 배포 (필요시)
3. 환경 변수 설정

## 라이선스

MIT


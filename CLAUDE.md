# EnterLab - AI 코칭 예약 시스템

## 개요
EnterLab은 AI 코칭 예약 및 자동 알림 웹서비스입니다.
사용자가 1:1 AI 코칭을 예약하면, 자동으로 SMS/이메일 알림이 발송되고,
관리자가 예약을 관리(확인/취소/완료)할 수 있습니다.

## 기술 스택
- **Backend**: Ruby on Rails 8.0 (Ruby >= 3.3.0)
- **Database**: PostgreSQL
- **Frontend**: Tailwind CSS + Hotwire (Turbo + Stimulus) + Importmap
- **Asset Pipeline**: Propshaft
- **Email**: SendGrid API
- **SMS**: Naver Cloud SENS API
- **Auth**: Devise (관리자 전용)
- **Background Jobs**: Sidekiq
- **Pagination**: Pagy
- **Encryption**: attr_encrypted (개인정보 암호화)

## 빌드 & 실행
- 빌드: `bundle install && npm install`
- 서버: `rails server` (포트 3000)
- Sidekiq: `bundle exec sidekiq`
- DB 마이그레이션: `rails db:migrate`
- Tailwind 빌드: `rails tailwindcss:build`
- 배포: Google Cloud Build (`cloudbuild.yaml`)

## 테스트
- 테스트: `rails test`
- 테스트 디렉토리: `test/`

## 디렉토리 구조
```
app/
  controllers/
    home_controller.rb          # 랜딩 페이지, 개인정보처리방침
    reservations_controller.rb  # 예약 생성 (사용자)
    admin/
      reservations_controller.rb # 예약 관리 (관리자)
  models/
    reservation.rb              # 예약 모델 (핵심 도메인)
    admin_user.rb               # 관리자 계정 (Devise)
  views/
    home/                       # 랜딩 페이지
    reservations/               # 예약 폼/확인
    admin/reservations/         # 관리자 대시보드
  mailers/
    reservation_mailer.rb       # 이메일 알림 (6종)
  jobs/
    sms_notification_job.rb     # SMS 발송 Job
    email_notification_job.rb   # 이메일 발송 Job
  services/
    sens_sms_service.rb         # Naver SENS SMS API 클라이언트
  javascript/controllers/       # Stimulus 컨트롤러
config/
  routes.rb                     # 라우팅 (사용자 + 관리자)
  database.yml                  # DB 설정
db/
  schema.rb                     # DB 스키마
```

## 코딩 컨벤션
- Ruby 스타일: Standard Ruby (frozen_string_literal)
- View: ERB 템플릿 + Tailwind CSS 유틸리티 클래스
- JavaScript: Stimulus 컨트롤러 패턴
- 비동기 처리: ActiveJob + Sidekiq
- 환경 변수: dotenv-rails (.env 파일)
- 한국어 UI, 코드 주석은 한국어

## 주요 환경 변수
- `DATABASE_USER`, `DATABASE_PASSWORD`, `DATABASE_HOST` - DB 접속
- `SENDGRID_API_KEY`, `SENDGRID_FROM_EMAIL` - 이메일
- `SENS_ACCESS_KEY`, `SENS_SECRET_KEY`, `SENS_SERVICE_ID`, `SENS_SENDER_NUMBER` - SMS
- `ADMIN_EMAIL` - 관리자 알림 수신
- `CONTACT_PHONE` - 고객 문의 전화번호
- `ENCRYPTION_KEY` - 개인정보 암호화 키

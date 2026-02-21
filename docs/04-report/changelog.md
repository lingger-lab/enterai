# EnterLab 변경 로그

## [2026-02-22] - config 기능 완료

### 추가됨 (Added)
- 이메일 알림 시스템 (SendGrid SMTP + ActionMailer)
  - `config/initializers/sendgrid.rb`: SendGrid SMTP 설정
  - `app/mailers/reservation_mailer.rb`: 예약 이메일 발송 클래스
  - 5개 이메일 템플릿: reservation_created, reservation_confirmed, reservation_cancelled, schedule_changed, reminder
  - `app/jobs/email_notification_job.rb`: 비동기 이메일 처리
- 24시간 리마인더 자동 스케줄링 (Sidekiq)
  - `app/jobs/reminder_notification_job.rb`: 리마인더 스케줄 관리
  - Reservation 모델에 schedule_reminder, reschedule_reminder, cancel_scheduled_reminder 메서드
  - `reminder_job_id` DB 필드 추가
- 프론트엔드 폼 유효성검증
  - validateCurrentStep() 활성화
  - alert() → 인라인 Tailwind 에러 메시지
  - console.log 디버깅 제거
- 관리자 대시보드 실시간 통계
  - @stats 해시: total, pending, confirmed, cancelled, completed, today, this_week (7개 지표)
  - 통계 카드 그리드 UI
- 페이지네이션 (Pagy 9.0)
  - `config/initializers/pagy.rb`: 한 페이지 20개 항목
  - `app/helpers/application_helper.rb`: Pagy 헬퍼 통합
  - Admin 컨트롤러 및 뷰에 pagy() 적용

### 변경됨 (Changed)
- `app/models/reservation.rb`
  - after_create, after_update 콜백에 이메일 발송 로직 추가
  - 리마인더 스케줄링 콜백 추가
  - reminder_job_id 필드 관리
- `app/controllers/admin/reservations_controller.rb`
  - @stats 해시 계산 로직
  - pagy() 페이지네이션 적용
  - 상태 변경 시 이메일 발송 로직
- `app/controllers/admin/base_controller.rb`
  - Pagy::Backend 통합
- `app/views/admin/reservations/index.html.erb`
  - 통계 카드 그리드 UI 추가
  - 페이지네이션 UI (pagy_nav) 추가
- `app/jobs/sms_notification_job.rb`
  - "reminder" SMS 메시지 타입 추가
- `app/javascript/controllers/step_form_controller.js`
  - validateCurrentStep() 활성화
  - alert() → showError()/clearErrors() 변경
- `Gemfile`
  - pagy ~> 9.0 의존성 추가

### 제거됨 (Fixed)
- 레거시 암호화 컬럼 6개 제거
  - name_encrypted, name_encrypted_iv
  - phone_encrypted, phone_encrypted_iv
  - email_encrypted, email_encrypted_iv
- 사용하지 않는 헬퍼 메서드 3개 제거
  - decrypted_name, decrypted_phone, decrypted_email
- 디버깅용 console.log 제거

---

## PDCA 메트릭

### config 기능 (완료)
- **설계 부합율**: 100% (35/35 항목)
- **반복 횟수**: 0회
- **소요 기간**: ~24시간
- **파일 변경**: 7개 수정, 11개 신규 생성
- **마이그레이션**: 2개 추가

### 프로젝트 진행률
- **전체 단계**: 9단계 중 1단계 완료 (Schema/Terminology)
- **Level**: Dynamic

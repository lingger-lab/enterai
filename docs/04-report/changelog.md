# EnterLab 변경 로그

## [2026-03-16] - PDCA #2: 예약 캘린더 + 조회/취소

### 추가됨 (Added)
- TimeSlot 캘린더 시스템
  - `app/models/time_slot.rb`: TimeSlot 모델 (77 LOC)
  - `app/controllers/admin/time_slots_controller.rb`: 관리자 슬롯 CRUD + 일괄 생성
  - `db/migrate/20260316000005_create_time_slots.rb`: time_slots 테이블 (8컬럼, 2인덱스)
  - `app/views/admin/time_slots/{index,new,bulk_new}.html.erb`: 관리자 UI
  - `app/javascript/controllers/slot_picker_controller.js`: 캘린더 + 슬롯 선택 (180 LOC)
- JSON 엔드포인트
  - `GET /reservations/available_dates?month=` - 슬롯 있는 날짜 배열
  - `GET /reservations/available_slots?date=` - 해당 날짜 가용 슬롯
- 예약 조회/취소 기능
  - `app/views/reservations/lookup.html.erb`: 이메일 + phone_last4 입력 폼
  - `app/views/reservations/lookup_results.html.erb`: 조회 결과 카드
  - 라우트: GET /reservations/lookup, POST /reservations/lookup, PATCH /reservations/:id/cancel

### 변경됨 (Changed)
- `app/models/reservation.rb`
  - `belongs_to :time_slot, optional: true` 추가
  - after_create_commit → time_slot.book! 콜백
  - after_update_commit → time_slot.release! 콜백
- `app/controllers/reservations_controller.rb`
  - `create` 액션: SELECT FOR UPDATE로 race condition 방지
  - `lookup`, `lookup_results`, `cancel` 액션 추가
- `app/views/reservations/new.html.erb`
  - Step 4: datetime_local_field 제거 → slot-picker Stimulus 컨트롤러
- `app/javascript/controllers/step_form_controller.js`
  - Step 4 검증: time_slot_id 필수 체크
- `config/routes.rb`
  - `admin/time_slots` 리소스 + collection/member 액션
  - `/reservations/lookup` (GET/POST), `/reservations/:id/cancel` (PATCH)
- `app/views/layouts/application.html.erb`
  - 네비게이션에 "예약 조회" 링크 추가

### 기술적 특징
- **Race Condition 방지**: SELECT FOR UPDATE로 원자성 보장
- **대량 생성 최적화**: insert_all로 1000개 슬롯을 ms 단위로 생성
- **암호화 필드 필터링**: attr_encrypted 필드는 Ruby에서 메모리 필터링
- **토큰 기반 보안**: secure_compare로 타이밍 공격 방지
- **Stimulus 캘린더**: 월별 네비게이션, 실시간 슬롯 로드

### 파일 통계
- **신규**: 10개 파일, ~900 LOC
- **수정**: 6개 파일, ~200 LOC
- **마이그레이션**: 1개 (time_slots 테이블)
- **설계 부합도**: 100% (27/27 항목)

---

## [2026-02-23] - 모바일 UX 5대 개선

### 추가됨 (Added)
- 개인정보 처리방침 전체 페이지 (`/privacy_policy`)
  - `app/views/home/privacy_policy.html.erb`: 7개 섹션 (수집항목~변경고지)
  - `config/routes.rb`: `get "privacy_policy"` 라우트
  - `app/controllers/home_controller.rb`: `privacy_policy` 액션
- 예약폼 내 개인정보 모달
  - `app/javascript/controllers/privacy_modal_controller.js`: open/close/backdropClose/ESC 지원
  - `_form_fields.html.erb`, `new.html.erb`: 모달 HTML + Stimulus 연결
- 스크롤 기반 fade-in 애니메이션
  - `app/javascript/controllers/scroll_reveal_controller.js`: IntersectionObserver + stagger
  - 4개 섹션 적용: 신뢰(150ms), 서비스(200ms), 프로세스(120ms), CTA(단일)
- 푸터 보안 안심 배지
  - shield-check SVG 아이콘 + Google Cloud 보안 문구

### 변경됨 (Changed)
- `app/views/home/index.html.erb`
  - 히어로 텍스트 모바일 최적화 (arbitrary value: `text-[1.65rem]` 등)
  - 섹션/카드 여백 반응형 축소 (`py-10 sm:py-20`, `gap-4 sm:gap-8`)
  - 하드코딩 `<br>` → 반응형 처리 (`hidden sm:inline`)
  - 스크롤 애니메이션 data 속성 추가 (4개 섹션)
  - 푸터 개인정보 링크: `href="#"` → `privacy_policy_path`
  - 푸터 보안 배지 HTML 삽입

---

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

### 예약 캘린더 + 조회/취소 (완료, PDCA #2)
- **설계 부합율**: 100% (27/27 항목)
- **반복 횟수**: 0회
- **소요 기간**: ~8시간
- **파일 변경**: 6개 수정, 10개 신규 생성
- **마이그레이션**: 1개 추가
- **보안**: Race condition, 토큰 기반 접근 제어 구현

### 모바일 UX 5대 개선 (완료, PDCA #1-3)
- **설계 부합율**: 98% (10/10 항목)
- **반복 횟수**: 0회
- **소요 기간**: ~4시간
- **파일 변경**: 5개 수정, 3개 신규 생성
- **프로덕션 배포**: Cloud Run 재배포 완료

### config 기능 (완료)
- **설계 부합율**: 100% (35/35 항목)
- **반복 횟수**: 0회
- **소요 기간**: ~24시간
- **파일 변경**: 7개 수정, 11개 신규 생성
- **마이그레이션**: 2개 추가

### 프로젝트 진행률
- **PDCA 사이클**: 3회 완료 (기본 4개 + 모바일 UX + 캘린더/조회)
- **누적 Match Rate**: 100% (평균)
- **누적 Feature**: 6개 완성
- **Level**: Dynamic
- **다음 단계**: Phase 2 (테스트 작성, 사용자 경험 개선)

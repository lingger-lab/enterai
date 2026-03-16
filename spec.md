# EnterLab - 기능 명세

## Feature 1: 예약 생성 (사용자)

### 요구사항
1. 사용자가 1:1 AI 코칭을 예약할 수 있다
2. 패키지 선택: STARTER(49만), STANDARD(80만), PREMIUM(120만)
3. 코칭 형태 선택: 출장/사무실/온라인
4. 선택 과목: AI 기초, AI 도구, 콘텐츠 제작, 마케팅 자동화, 수익화 전략
5. 개인정보 동의 필수

### 데이터 모델: Reservation
| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| name | string | O | 이름 (암호화 저장) |
| phone | string | O | 연락처 (10-11자리, 암호화) |
| email | string | O | 이메일 (암호화) |
| reservation_datetime | datetime | O | 예약 일시 |
| coaching_type | string | O | 코칭 형태 |
| selected_subjects | string[] | - | 선택 과목 (배열) |
| requests | text | - | 요청사항 |
| privacy_agreed | boolean | O | 개인정보 동의 |
| package | string | O | 패키지 (starter/standard/premium) |
| status | string | O | 상태 (pending/confirmed/cancelled/completed) |
| reminder_job_id | string | - | 리마인더 Job ID |

### API (라우트)
- `GET /` - 랜딩 페이지
- `GET /reservations/new?package=starter` - 예약 폼 (패키지 사전 선택)
- `POST /reservations` - 예약 생성
- `GET /reservations/:id` - 예약 확인 페이지

### 비즈니스 로직
- 예약 생성 시 SMS + 이메일 자동 발송 (비동기)
- 예약 생성 시 24시간 전 리마인더 자동 스케줄링
- Turbo Stream으로 폼 제출 애니메이션 처리

---

## Feature 2: 예약 관리 (관리자)

### 요구사항
1. Devise 인증된 관리자만 접근 가능
2. 예약 목록 조회 (상태별 필터, 페이지네이션)
3. 예약 상세 조회/수정
4. 예약 상태 변경 (pending → confirmed/cancelled/completed)
5. 수동 SMS 발송

### API (라우트)
- `GET /admin` - 관리자 대시보드 (예약 목록)
- `GET /admin/reservations/:id` - 예약 상세
- `GET /admin/reservations/:id/edit` - 예약 수정 폼
- `PATCH /admin/reservations/:id` - 예약 수정
- `PATCH /admin/reservations/:id/update_status` - 상태 변경
- `POST /admin/reservations/:id/send_sms` - 수동 SMS 발송

### 비즈니스 로직
- 대시보드에 통계 표시 (전체/상태별/오늘/이번주)
- 상태 변경 시 SMS + 이메일 자동 발송
- 일정 변경 시 SMS + 이메일 자동 발송 + 리마인더 재스케줄링

---

## Feature 3: 알림 시스템

### 이메일 알림 (SendGrid, 6종)
1. `reservation_created` - 예약 완료 안내 (사용자)
2. `reservation_confirmed` - 예약 확정 안내 (사용자)
3. `reservation_cancelled` - 예약 취소 안내 (사용자)
4. `schedule_changed` - 일정 변경 안내 (사용자)
5. `reminder` - 24시간 전 리마인더 (사용자)
6. `admin_notification` - 신규 예약 알림 (관리자)

### SMS 알림 (Naver SENS, 7종)
1. `created` - 예약 완료
2. `confirmed` - 예약 확정
3. `cancelled` - 예약 취소
4. `schedule_changed` - 일정 변경
5. `reminder` - 24시간 전 리마인더
6. `manual` - 관리자 수동 발송
7. 기본 알림

### 비동기 처리
- `EmailNotificationJob` - 이메일 발송 (Sidekiq)
- `SmsNotificationJob` - SMS 발송 (Sidekiq)
- `ReminderNotificationJob` - 리마인더 스케줄링 (Sidekiq, wait_until)

---

## Feature 4: 랜딩 페이지

### 요구사항
1. 서비스 소개 및 패키지 안내
2. 예약 CTA 버튼 (패키지별)
3. 개인정보 처리방침 페이지
4. 반응형 모바일 UI (Tailwind CSS)

### Stimulus 컨트롤러
- `mobile_menu_controller` - 모바일 메뉴
- `step_form_controller` - 단계별 폼
- `stream_card_controller` - 카드 애니메이션
- `scroll_reveal_controller` - 스크롤 애니메이션
- `privacy_modal_controller` - 개인정보 모달
- `tabs_controller` - 탭 UI
- `cta_button_controller` - CTA 버튼 인터랙션
- `icon_hover_controller` - 아이콘 호버 효과
- `magnetic_text_controller` - 마그네틱 텍스트 애니메이션

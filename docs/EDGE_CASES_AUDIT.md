# EnterLab 엣지 케이스 점검 보고서

> 작성: 2026-05-15
> 컨텍스트: 출시 전 로직/플로우 엣지 케이스 전수 점검
> 발견 사항을 심각도별로 분류, 액션 권장.

---

## 0. 종합 결과

| 심각도 | 개수 | 대표 이슈 |
|------|------|---------|
| 🔴 **HIGH** | 4 | 시간대 변환 버그, 슬롯 동시 예약 race, lookup 메모리 부담 |
| 🟡 **MEDIUM** | 8 | cancelled→pending 전이, 과거 시간 예약, 콜백 실패 처리 |
| 🟢 **LOW** | 7 | 중복 예약, 빈 상태 UX 등 |
| **합계** | **19** | |

---

## 1. 🔴 HIGH — 데이터/로직 무결성

### 1.1 시간대 변환 버그 (의심)

**위치**: `app/controllers/reservations_controller.rb`

```ruby
@reservation.reservation_datetime = slot.date.to_datetime.change(
  hour: slot.start_time.utc.hour,
  min: slot.start_time.utc.min
)
```

**문제**:
- `time_slots.start_time` = PostgreSQL `TIME` 타입 (시간대 정보 없음)
- Rails는 `Time.zone="Seoul"`에 따라 파싱하지만 `time` 타입은 모호
- `.utc.hour` 호출 시:
  - 만약 start_time이 한국 시간 10:00이면 → `.utc.hour`는 **01** (KST→UTC 9시간 차) 가능
  - 또는 같은 10일 수도 (구현에 따라)
- 결과: **사용자가 본 "10:00" 슬롯과 실제 reservation_datetime이 다를 가능성**

**확인 방법**: production DB의 실제 reservation_datetime 값과 slot.start_time 비교
**영향도**: 🔴 높음 (예약 시간이 9시간 어긋날 수 있음)
**권장**:
```ruby
# 옵션 A: time 컬럼 그대로 사용
hours = slot.start_time.hour
mins = slot.start_time.min
# (확인: slot.start_time.hour가 한국 시간을 반환하는지)

# 옵션 B: time → timestamp 통합
# DB 컬럼을 datetime으로 변경 (마이그레이션 필요)
```

### 1.2 슬롯 동시 예약 Race Condition

**위치**: `reservations_controller.rb#create`

```ruby
slot = TimeSlot.lock.find_by(id: @reservation.time_slot_id)
unless slot&.available?
  ...
end
@reservation.reservation_datetime = ...
# 트랜잭션 미명시
if @reservation.save  # 여기서 commit
  ...
end
```

**문제**:
- `lock`은 `SELECT FOR UPDATE` — 트랜잭션 안에서만 의미 있음
- 컨트롤러 액션은 자동 트랜잭션 아님
- `@reservation.save`는 자체 트랜잭션이지만 위 lock과 별개
- 두 사용자가 동시에 같은 슬롯 요청 시 **둘 다 통과 가능**

**영향도**: 🔴 높음 (월 4명 한도 깨질 수 있음)
**권장**:
```ruby
ActiveRecord::Base.transaction do
  slot = TimeSlot.lock.find_by(id: @reservation.time_slot_id)
  raise ActiveRecord::Rollback unless slot&.available?
  @reservation.reservation_datetime = ...
  @reservation.save!
  slot.book!  # 같은 트랜잭션 내 슬롯 잡기
end
```
또는 `unique_by` constraint + retry 패턴.

### 1.3 Lookup 메모리 부담 (예약 누적 시)

**위치**: `reservations_controller.rb#lookup_results`

```ruby
@reservations = Reservation.where(status: %w[pending confirmed])
                           .select { |r| r.email&.downcase == email && r.phone&.last(4) == phone_last4 }
```

**문제**:
- 모든 pending/confirmed 예약을 **메모리에 로드** + 각각 `decrypt`
- attr_encrypted라 DB 쿼리 불가
- 1,000건 이상이면 매 lookup마다 1,000건 복호화 → 응답 지연

**영향도**: 🟡 중간 (현재 규모 OK, 1년 후 문제)
**권장**:
1. `find_each` 사용 (배치 처리)
2. 또는 별도 검색용 hash 컬럼 추가 (email_hash, phone_last4_hash)
3. 또는 회원 전환 유도 (lookup 자체를 점진 deprecate)

### 1.4 콜백 실패 시 데이터 불일치

**위치**: `Reservation` 모델

```ruby
after_create_commit :send_notifications
after_create_commit :mark_slot_booked
after_create_commit :schedule_reminder
```

**문제**:
- `mark_slot_booked` 실패 시 (예: slot 삭제됨) reservation은 살아있지만 slot 미 booked → **데이터 불일치**
- `send_notifications`도 동일

**영향도**: 🟡 중간 (드물게 발생)
**권장**:
- `mark_slot_booked`를 트랜잭션 내로 (after_create vs after_create_commit 차이)
- 또는 명시 에러 로깅 + 관리자 알림

---

## 2. 🟡 MEDIUM — 비즈니스 로직 / UX

### 2.1 과거 시간 예약 가능

```ruby
validates :reservation_datetime, presence: true
# future 검증 없음
```

**문제**: 사용자가 폼 조작 시 어제 날짜로 예약 가능
**권장**: `validate :datetime_must_be_future`

### 2.2 Cancelled → Pending 전이 (의도 모호)

```ruby
VALID_TRANSITIONS = {
  ...
  "cancelled" => %w[pending],  # 취소 → 대기?
}
```

**문제**:
- 취소된 예약을 다시 pending으로? 슬롯은 이미 release됨
- 다시 pending 되면 슬롯도 다시 잡아야 하는데 처리 없음

**권장**:
- 의도 확인 후 `"cancelled" => []`로 변경
- 또는 관리자만 가능하도록 권한 분리

### 2.3 Reservation `update!` 실패 시 알림 잡 발송

```ruby
@reservation.update!(status: "cancelled")
SmsNotificationJob.perform_later(@reservation.id, "cancelled")
EmailNotificationJob.perform_later(@reservation.id, "cancelled")
```

**문제**: `update!` 실패 시 예외 raise → 잡 발송 안 함 (OK). 단, `update`(! 없음)면 발송 가능.
**현재 상태**: `update!` 사용 ✓

### 2.4 동일 이메일 다중 회원 가입 시도

- Devise `:validatable` → email unique 자동 검증 ✓
- 다른 이메일로 가입해서 같은 phone 사용? → phone 중복 검증 없음

**권장**: 의도된 동작인지 확인 (대표 1인이 여러 계정 만들 수 있음)

### 2.5 회원 탈퇴 시 Reservation 처리

```ruby
has_many :reservations, dependent: :nullify
```

**문제**: 사용자 탈퇴 시 reservation.user_id = nil → 비회원 예약처럼 유지
**의도**: OK (PIPA 관점 — 예약 자체는 사업자 보관 의무 있음)
**확인**: 현재 User 모델에 destroy UI 없음 (Devise destroyable 미적용)

### 2.6 토큰 brute force (이론적)

- access_token = `SecureRandom.urlsafe_base64(32)` — 256bit
- 추측 불가능 수준 ✓
- 단, lookup의 phone 4자리는 10,000 조합 → rack-attack으로 차단 ✓

### 2.7 슬롯 삭제 권한

```ruby
def destroy
  if @time_slot.booked?
    redirect ... alert: "예약된 슬롯은 삭제할 수 없습니다."
```

✅ 좋음. 단, "blocked" 상태 슬롯에 이미 예약이 연결되어 있다면?
- 현재 booked만 체크 → blocked로 변경 후 삭제 가능 → 데이터 무결성 ?

### 2.8 같은 이메일 + 시간 중복 예약

- 같은 사용자가 같은 시간에 다른 예약? 불가 (슬롯 booked되면 못 잡음) ✓
- 다른 슬롯 동시 예약? 가능 (의도일 수도)

---

## 3. 🟢 LOW — 경미한 UX / 일관성

### 3.1 후기 작성 후 수정/삭제 불가

```ruby
def create  # 한 번만 작성 가능
  if @review.submitted?
    redirect ... "이미 후기를 작성하셨습니다."
```

**현재**: 수정 불가
**권장**: 의도된 정책. 수정 허용 시 신뢰성 ↓ 가능.

### 3.2 결제 링크 만료 (스캐폴드)

- 현재 Payment 모델에 만료 시간 없음
- 향후 활성화 시 추가 필요 (예: 24h 후 만료)

### 3.3 폼 localStorage 데이터 호환성

- 폼 구조 변경 시 옛 데이터 복원 → 일부 필드 깨질 수 있음
- 현재 step_form 컨트롤러는 try/catch로 안전 처리 ✓

### 3.4 lookup_results 빈 결과 UX

- 현재: `flash.now[:alert]` + lookup 폼 다시 표시
- 가능: "예약 신청해보세요" CTA 추가 (전환율)

### 3.5 새 슬롯 추가 시 시점

- bulk_create로 한 번에 많이 생성 시 알림 없음
- 관리자만 보는 페이지라 OK

### 3.6 모바일 키보드 대응

- `inputmode="numeric"` 적용 (전화번호) ✓
- 한글 입력 모드 자동 전환 — 브라우저 의존

### 3.7 카카오톡 인앱 브라우저 행동

- 미검증 (이전 보고서에서도 지적)
- 일부 JS API 미지원 가능

---

## 4. 즉시 처리 권장 (1~2시간)

### 4.1 시간대 변환 검증 (HIGH 1.1)

production DB에서 임의 reservation 1건 select 후:
```sql
SELECT r.reservation_datetime, ts.date, ts.start_time
FROM reservations r
JOIN time_slots ts ON r.time_slot_id = ts.id
LIMIT 5;
```
→ 일치하면 OK, 9시간 차이면 버그.

### 4.2 슬롯 동시 예약 트랜잭션 보강 (HIGH 1.2)

```ruby
def create
  ActiveRecord::Base.transaction do
    @reservation = Reservation.new(reservation_params)
    @reservation.user_id = current_user.id if user_signed_in?

    if @reservation.time_slot_id.present?
      slot = TimeSlot.lock.find_by(id: @reservation.time_slot_id)
      unless slot&.available?
        @reservation.errors.add(:base, "선택한 시간대가 이미 예약되었습니다.")
        raise ActiveRecord::Rollback
      end
      @reservation.reservation_datetime = ...
    end

    @reservation.save!
  end
  # ...
end
```

### 4.3 과거 시간 예약 차단 (MEDIUM 2.1)

```ruby
# Reservation 모델
validate :reservation_datetime_must_be_future

def reservation_datetime_must_be_future
  return unless reservation_datetime.present?
  errors.add(:reservation_datetime, "과거 시간은 선택할 수 없습니다") if reservation_datetime < Time.current
end
```

### 4.4 Cancelled → Pending 전이 제거 (MEDIUM 2.2)

```ruby
VALID_TRANSITIONS = {
  "pending" => %w[confirmed cancelled],
  "confirmed" => %w[cancelled completed],
  "cancelled" => [],  # 종료 상태
  "completed" => []
}.freeze
```

---

## 5. 운영 중 모니터링 권장

| 항목 | 모니터링 |
|------|---------|
| 슬롯 중복 예약 | 동일 time_slot_id에 2건 이상 reservation 있는지 daily 체크 |
| 시간 일치 | reservation_datetime vs slot.start_time 일치 검증 |
| 콜백 실패 | Sentry로 mark_slot_booked 등 실패 캡처 |
| Lookup 응답 시간 | 5초 초과 시 알림 |

---

## 6. 종합 결론

### 시급 처리 4건 (1~2시간 작업)

1. 🔴 **시간대 변환 검증** (production DB 확인)
2. 🔴 **슬롯 동시 예약 트랜잭션 보강**
3. 🟡 **과거 시간 예약 차단**
4. 🟡 **Cancelled → Pending 전이 제거**

### 운영 중 점진 처리 (3건)

5. 🟡 **Lookup 메모리 부담** (예약 1000건+ 시점)
6. 🟢 **결제 만료** (결제 활성화 시)
7. 🟢 **빈 상태 UX 개선**

### 전반 평가

> **현재 상태에서도 운영 가능**. 하지만 **시간대 변환 검증**과 **race condition**은 결제 도입 전 정리 권장 (실 사용자 데이터에 영향 가능).

---

## 7. 액션 옵션

| 옵션 | 작업 | 시간 |
|------|------|------|
| **A. 즉시 4건 수정 + 배포** | 시간대/race/과거/cancelled | 1~2시간 |
| **B. 시간대만 검증 후 결정** | production DB 확인 → 필요 시 수정 | 10분 |
| **C. 보류 후 결제 도입 시 일괄** | Q1 결제 도입 시 함께 | - |

---

작성: 2026-05-15
다음 검토: 첫 결제 도입 직후

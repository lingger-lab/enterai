# Security Scan v3 - EnterLab AI Coaching Reservation System

**Date**: 2026-03-16
**Scan Type**: Third-pass comprehensive review (post feature expansion)
**Stack**: Rails 8.0, PostgreSQL, Sidekiq, Devise, attr_encrypted, rack-attack, Chart.js
**Auditor**: Security Architect Agent
**Scope**: All new features added in current session -- TimeSlot CRUD, Review system, Chart.js dashboard, KakaoAlimtalkService, Reservation lookup/cancel, Slot picker JSON endpoints

---

## Executive Summary

Several v2 high-severity findings have been remediated: `coaching_type` now has inclusion validation (H-01), `selected_subjects` has server-side validation (H-02), and access token comparison uses `secure_compare` (M-05). However, the rapid addition of 7+ features introduced **0 critical**, **3 high**, **4 medium**, and **3 low** new issues not present in previous scans.

| Severity | Count | Status |
|----------|-------|--------|
| CRITICAL | 0 | -- |
| HIGH | 3 | Fix before release |
| MEDIUM | 4 | Fix in next sprint |
| LOW | 3 | Track in backlog |

### v2 Issues Now Resolved

| v2 Finding | Status |
|-----------|--------|
| H-01: coaching_type missing inclusion validation | FIXED (reservation.rb:73) |
| H-02: selected_subjects accepts arbitrary values | FIXED (validate_selected_subjects) |
| M-05: Token comparison not constant-time | FIXED (secure_compare in show + cancel) |

### v2 Issues Still Open (Not Re-Listed)

H-03 (.env credentials), M-01 (paranoid mode), M-02 (session timeout), M-03 (CSP unsafe-inline), M-04 (docker-compose secrets), L-01 through L-04 remain open from v2. See `security-scan-v2.report.md`.

---

## HIGH Severity Findings

### H-04: Reservation Lookup Loads ALL Reservations Into Memory (A01 - Broken Access Control / A04 - Insecure Design)

**File**: `app/controllers/reservations_controller.rb:78-79`

```ruby
@reservations = Reservation.where(status: %w[pending confirmed])
                           .select { |r| r.email&.downcase == email && r.phone&.last(4) == phone_last4 }
```

**Issue**: This loads every pending/confirmed reservation from the database into Ruby memory, then decrypts every record's email and phone to filter in application code. This has three compounding problems:

1. **Denial of Service**: With N reservations, this performs N decryption operations per request. An attacker making repeated lookup requests can exhaust server CPU. As the reservation count grows, this becomes progressively worse.
2. **No rate limiting**: The lookup endpoint (`POST /reservations/lookup`) is not covered by rack-attack. The only throttle rules cover `/reservations` (POST create) and `/admin/sign_in`. An attacker can make unlimited lookup requests.
3. **Enumeration via timing**: A successful match (N reservations found) vs. no match produces different response times and different response bodies ("일치하는 예약을 찾을 수 없습니다" vs. results page). Combined with no rate limiting, an attacker can enumerate which email addresses have reservations.

**Impact**: CPU exhaustion (DoS), email enumeration, brute force of phone last-4 digits (only 10,000 combinations).

**Fix**:
```ruby
# 1. Add rate limiting in rack_attack.rb
Rack::Attack.throttle("reservations/lookup/ip", limit: 10, period: 15.minutes) do |req|
  req.ip if req.path == "/reservations/lookup" && req.post?
end

# 2. Add an encrypted_email_hash column for indexed lookups (or use blind index gem)
# This avoids loading all records for filtering.

# 3. As a short-term mitigation, add a CAPTCHA or add artificial delay
```

---

### H-05: Review Write Form Does Not Use `secure_compare` for Token Lookup (A07 - Identification/Authentication Failures)

**File**: `app/controllers/reviews_controller.rb:3,19`

```ruby
# write action
@review = Review.find_by(access_token: params[:token])

# create action
@review = Review.find_by(access_token: params[:review][:access_token])
```

**Issue**: Review access tokens are looked up via `find_by`, which performs a database query using the token value directly. While this is standard for token-based lookups, the review write form also exposes the access_token in a hidden field (write.html.erb:17):

```erb
<%= f.hidden_field :access_token, value: @review.access_token %>
```

The critical issue: the `create` action trusts the `access_token` from the submitted form params. There is no secondary verification (e.g., checking the review has not already been submitted). While `submitted?` is checked in the `write` action, **the create action does not check `submitted?`**. This means:

1. A user who has already submitted a review can POST again to the create endpoint with the same access token and overwrite their previous review content, rating, author_name, and category.
2. If someone obtains a review token (from email, URL bar, etc.), they can submit content for that review even after it was already submitted.

**Impact**: Review content tampering. A completed review can be silently overwritten.

**Fix**:
```ruby
def create
  @review = Review.find_by(access_token: params[:review][:access_token])

  unless @review
    redirect_to root_path, alert: "유효하지 않은 요청입니다."
    return
  end

  if @review.submitted?
    redirect_to review_path(@review), alert: "이미 후기를 작성하셨습니다."
    return
  end

  # ... rest of update logic
end
```

---

### H-06: Review Show Page Is Publicly Accessible Without Token (A01 - Broken Access Control)

**File**: `app/controllers/reviews_controller.rb:34-37`

```ruby
def show
  @review = Review.find(params[:id])
  @reservation = @review.reservation
end
```

**Issue**: The review show page is accessible to anyone who knows or guesses the review ID (sequential integer). It displays the review content, author name, rating, and -- critically -- `@reservation` is loaded and available in the template. The current `show.html.erb` displays the reservation's coaching_type and datetime. While it does not currently display phone/email, the `@reservation` object is fully loaded with decrypted PII in the view context. A future template change could accidentally expose this data.

Additionally, unpublished reviews (those pending admin approval via `is_published: false`) are visible via the show action to anyone with the ID.

**Impact**: Information disclosure of unpublished review content. Potential PII exposure from associated reservation.

**Fix**:
```ruby
def show
  @review = Review.find_by!(id: params[:id], access_token: params[:token])
  @reservation = @review.reservation
rescue ActiveRecord::RecordNotFound
  redirect_to root_path, alert: "유효하지 않은 링크입니다."
end
```

---

## MEDIUM Severity Findings

### M-06: JSON Slot Endpoints Have No Rate Limiting (A05 - Security Misconfiguration)

**Files**: `app/controllers/reservations_controller.rb:44-64`, `config/initializers/rack_attack.rb`

**Issue**: The `available_dates` and `available_slots` JSON endpoints have no rate limiting. These endpoints are public (no authentication required) and return data about the business's scheduling availability. An attacker could:
1. Scrape all available dates/slots to profile the business's capacity
2. Use rapid polling to detect when slots open (competitive advantage in high-demand scenarios)
3. Use these endpoints as an amplification vector since they hit the database on every request

**Impact**: Business intelligence leakage, potential DoS vector.

**Fix**: Add rack-attack throttle rules:
```ruby
Rack::Attack.throttle("slots/api/ip", limit: 30, period: 1.minute) do |req|
  req.ip if req.path.match?(/reservations\/available_(dates|slots)/) && req.get?
end
```

---

### M-07: Bulk TimeSlot Creation Has No Upper Bound on Date Range (A04 - Insecure Design)

**File**: `app/controllers/admin/time_slots_controller.rb:37-65`, `app/models/time_slot.rb:39-69`

**Issue**: The `bulk_create` action accepts arbitrary `start_date` and `end_date` params. While it checks `interval > 0` and `start_hour < end_hour`, there is no upper bound on the date range. An admin (or an attacker who compromises an admin account) could create slots for a 10-year range, generating hundreds of thousands of database records in a single request via `insert_all`.

The `bulk_create` method in the model builds all slots in memory before inserting:
```ruby
(start_date..end_date).each do |date|  # unbounded range
  # ...
  slots << { ... }                      # grows without limit
end
insert_all(slots, ...)                  # single massive INSERT
```

**Impact**: Memory exhaustion, database bloat, potential DoS.

**Fix**: Add a maximum range limit (e.g., 90 days) in the controller:
```ruby
if (end_date - start_date).to_i > 90
  flash[:alert] = "최대 90일 범위까지 생성 가능합니다."
  render :bulk_new, status: :unprocessable_entity and return
end
```

---

### M-08: `Date.parse` on Unvalidated Params Can Raise Unhandled Exceptions (A05 - Security Misconfiguration)

**Files**:
- `app/controllers/reservations_controller.rb:45` -- `available_dates` action
- `app/controllers/admin/time_slots_controller.rb:5` -- `index` action
- `app/controllers/admin/time_slots_controller.rb:38-39` -- `bulk_create` action

**Issue**: `Date.parse(params[:month])` and `Date.parse(params[:start_date])` are called on user-provided parameters without rescue. While `available_slots` has a `rescue Date::Error`, the other three locations do not. Sending `?month=not-a-date` to these endpoints will raise an uncaught `Date::Error` exception, resulting in a 500 error.

In production with `consider_all_requests_local = false`, this returns a generic error page, but:
1. It pollutes error monitoring / logs with attacker-generated noise
2. The `bulk_create` action partially rescues with `rescue => e` at line 62, but the error message `e.message` from `Date.parse` is interpolated into the flash: `"생성 실패: #{e.message}"`. This leaks the internal exception class and message to the admin user, which while less severe (admin-only), is still information disclosure.

**Impact**: Unhandled exceptions on public endpoints, minor information disclosure on admin endpoint.

**Fix**: Add `rescue Date::Error` or use a safe parse pattern:
```ruby
def safe_parse_date(str, fallback = Date.current)
  Date.parse(str.to_s)
rescue Date::Error
  fallback
end
```

---

### M-09: Admin Email Subject Leaks Decrypted Customer Name (A02 - Cryptographic Failures)

**File**: `app/mailers/reservation_mailer.rb:48`

```ruby
mail(to: admin_email, subject: "[EnterLab] 새로운 예약이 접수되었습니다 - #{reservation.name}")
```

**Issue**: The customer's decrypted name is included in the email subject line. Email subjects are:
1. Stored in plaintext in email provider logs (SendGrid activity feed, etc.)
2. Visible in email notification previews on lock screens
3. Not encrypted in transit between mail servers (SMTP metadata)
4. Indexed by email search engines

This partially defeats the purpose of encrypting `name` with attr_encrypted, as the plaintext leaks through the email channel.

**Impact**: PII (customer name) exposed in email metadata, contradicting the encryption design intent.

**Fix**:
```ruby
mail(to: admin_email, subject: "[EnterLab] 새로운 예약이 접수되었습니다")
```

Include the name in the email body only, where it benefits from TLS in transit.

---

## LOW Severity Findings

### L-05: Review `create` Action Permits `access_token` Update via Mass Assignment (A01 - Broken Access Control)

**File**: `app/controllers/reviews_controller.rb:42`

**Issue**: The hidden field submits `access_token` as part of the review params, but it is not in the `review_params` permit list (only `rating`, `content`, `author_name`, `category` are permitted). This is actually **correct** -- the access_token is used for lookup, not for update.

However, the `create` action calls `@review.update(review_params)` on an existing review record. The `review_params` does not include `is_published`, which is good. But it also does not include `reservation_id`, meaning an attacker cannot reassign the review to a different reservation. This is secure by default.

**Note**: This is actually a positive observation rather than a finding. Included for completeness of the audit trail.

**Actual finding**: The `access_token` is transmitted in a hidden form field in cleartext HTML. If the page is cached by a CDN or browser, the token is persisted. This is a defense-in-depth concern similar to L-03 (token in query params).

**Impact**: Low risk token exposure via page cache.

---

### L-06: `send_review_request` Callback Can Silently Fail Without Retry (A09 - Logging/Monitoring Failures)

**File**: `app/models/reservation.rb:126-129`

```ruby
def send_review_request
  return if review.present?
  review = create_review!
  EmailNotificationJob.perform_later(self.id, "review_request")
end
```

**Issue**: If `create_review!` raises an exception (e.g., due to a database constraint violation), the `after_update_commit` callback will propagate the error. However, if the email job fails, there is no retry or monitoring specifically for review request emails. Additionally, there is a subtle bug: the local variable `review` shadows the `review` association method. After `review = create_review!`, the subsequent call to `review.present?` in a future invocation will still correctly check the association (since it is a method, not using the local variable). But this shadow naming is confusing and could lead to maintenance bugs.

**Impact**: Low -- potential for missed review request emails with no visibility.

**Fix**: Rename the local variable:
```ruby
def send_review_request
  return if review.present?
  new_review = create_review!
  EmailNotificationJob.perform_later(self.id, "review_request")
end
```

---

### L-07: Slot Picker Exposes Internal TimeSlot IDs in JSON Response (A04 - Insecure Design)

**File**: `app/controllers/reservations_controller.rb:54-61`

```ruby
render json: slots.map { |s|
  {
    id: s.id,
    start_time: s.start_time.strftime("%H:%M"),
    end_time: s.end_time.strftime("%H:%M"),
    coaching_type: s.coaching_type
  }
}
```

**Issue**: The `available_slots` endpoint returns internal database IDs of time slots. While the `create` action properly validates that the submitted `time_slot_id` refers to an available slot (using `TimeSlot.lock.find_by`), exposing sequential IDs allows an attacker to enumerate all time slot IDs and attempt to book blocked or booked slots by guessing IDs outside the returned set.

The current booking logic correctly rejects non-available slots:
```ruby
slot = TimeSlot.lock.find_by(id: @reservation.time_slot_id)
unless slot&.available?
```

This means the exposure is informational only -- the actual booking is protected.

**Impact**: Low -- information disclosure of internal IDs. The booking logic is correctly protected.

**Recommendation**: Consider using UUIDs or opaque tokens instead of sequential IDs for public-facing slot references.

---

## Positive Security Observations (New Features)

1. **TimeSlot booking uses pessimistic locking**: `TimeSlot.lock.find_by` prevents race conditions on double-booking
2. **Admin controllers inherit from `Admin::BaseController`**: All new admin controllers (TimeSlotsController, ReviewsController) correctly inherit from `Admin::BaseController` which enforces `authenticate_admin_user!`
3. **Review access tokens are cryptographically random**: `SecureRandom.urlsafe_base64(32)` provides 256-bit entropy
4. **Review uniqueness per reservation**: `validates :reservation_id, uniqueness: true` at model + DB index level prevents duplicate reviews
5. **Strong params correctly configured**: TimeSlot permits only `date, start_time, end_time, coaching_type`. Review permits only `rating, content, author_name, category`
6. **No `raw` or `html_safe` in any new templates**: All ERB output uses default auto-escaping (XSS safe)
7. **Kakao service uses ENV for credentials**: No hardcoded API keys; feature-flagged via `KAKAO_ALIMTALK_ENABLED`
8. **Kakao service masks phone numbers in logs**: `mask_phone` method prevents PII in log output
9. **CSRF protection active on all new forms**: `button_to` and `form_with` include CSRF tokens automatically
10. **TimeSlot status transitions are guarded**: Cannot delete or block a booked slot
11. **Cancel action uses `secure_compare`**: Token verification is timing-safe
12. **Reservation status transitions use state machine**: `can_transition_to?` prevents invalid state changes

---

## Arel.sql Usage Assessment (Question #5)

**Files**: `app/controllers/admin/reservations_controller.rb:18-19, 28-29`

```ruby
.group(Arel.sql("TO_CHAR(created_at, 'YYYY-MM')"))
.order(Arel.sql("TO_CHAR(created_at, 'YYYY-MM')"))
.group(Arel.sql("EXTRACT(HOUR FROM reservation_datetime)::integer"))
.order(Arel.sql("EXTRACT(HOUR FROM reservation_datetime)::integer"))
```

**Assessment**: These `Arel.sql` calls use **hardcoded SQL fragments** -- no user input is interpolated. The column names and functions are string literals. This is safe against SQL injection. The `Arel.sql` wrapper is necessary because Rails' query interface does not natively support `TO_CHAR` and `EXTRACT`. No action required.

---

## Recommendations Priority Matrix (New Findings Only)

| Priority | Finding | Effort | Impact |
|----------|---------|--------|--------|
| 1 | H-04: Lookup loads all records + no rate limit | 1 hr (rate limit: 5 min, blind index: 2 hr) | Prevents DoS + enumeration |
| 2 | H-05: Review overwrite (no submitted? check in create) | 5 min | Prevents content tampering |
| 3 | H-06: Review show publicly accessible without token | 10 min | Prevents info disclosure |
| 4 | M-06: Slot endpoints no rate limit | 5 min | Prevents scraping/DoS |
| 5 | M-07: Bulk create no date range limit | 5 min | Prevents resource exhaustion |
| 6 | M-08: Unhandled Date.parse exceptions | 15 min | Prevents 500 errors |
| 7 | M-09: Admin email subject leaks name | 2 min | Aligns with encryption intent |
| 8 | L-06: Variable shadow in send_review_request | 2 min | Code clarity |
| 9 | L-07: Sequential IDs in slot API | Low priority | Defense in depth |

---

## Cumulative Issue Tracker (All Scans)

| Finding | Severity | Scan | Status |
|---------|----------|------|--------|
| ~~C-01: Hardcoded encryption fallback~~ | Critical | v1 | FIXED |
| ~~C-02: IDOR via sequential IDs~~ | Critical | v1 | FIXED |
| ~~H-01: coaching_type no inclusion~~ | High | v2 | FIXED (v3 confirmed) |
| ~~H-02: selected_subjects no validation~~ | High | v2 | FIXED (v3 confirmed) |
| H-03: .env contains real credentials | High | v2 | OPEN |
| **H-04: Lookup loads all records, no rate limit** | High | v3 | **NEW** |
| **H-05: Review create allows overwrite** | High | v3 | **NEW** |
| **H-06: Review show no auth** | High | v3 | **NEW** |
| M-01: Paranoid mode disabled | Medium | v2 | OPEN |
| M-02: No admin session timeout | Medium | v2 | OPEN |
| M-03: CSP unsafe-inline | Medium | v2 | OPEN |
| M-04: docker-compose hardcoded secret | Medium | v2 | OPEN |
| ~~M-05: Token compare not constant-time~~ | Medium | v2 | FIXED (v3 confirmed) |
| **M-06: Slot endpoints no rate limit** | Medium | v3 | **NEW** |
| **M-07: Bulk create no range limit** | Medium | v3 | **NEW** |
| **M-08: Unhandled Date.parse** | Medium | v3 | **NEW** |
| **M-09: Admin email leaks name** | Medium | v3 | **NEW** |
| L-01: PII shown unmasked in show page | Low | v2 | OPEN |
| L-02: Missing Referrer/Permissions headers | Low | v2 | OPEN |
| L-03: Token in query parameter | Low | v2 | OPEN |
| L-04: console.log in production | Low | v2 | OPEN |
| **L-05: Token in hidden field (cache risk)** | Low | v3 | **NEW** |
| **L-06: Variable shadow in callback** | Low | v3 | **NEW** |
| **L-07: Sequential IDs in slot API** | Low | v3 | **NEW** |

**Total open**: 0 critical, 4 high, 8 medium, 7 low

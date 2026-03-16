# Code Review Report: EnterLab AI Coaching Reservation System

## Analysis Target
- Path: `c:\workspace\enterai-main`
- Files reviewed: 22 (models, controllers, services, jobs, views, JS controllers, routes, schema)
- Analysis date: 2026-03-16
- Framework: Ruby on Rails 8.0, Stimulus JS, Tailwind CSS

## Quality Score: 62/100

---

## Issues Found

### CRITICAL (Immediate Fix Required)

| # | File | Line | Issue | Recommended Action |
|---|------|------|-------|--------------------|
| C1 | `app/models/reservation.rb` | 3-5 | **Insecure encryption key fallback.** `ENV.fetch("ENCRYPTION_KEY", "a" * 32)` provides a trivially guessable default key. If `ENCRYPTION_KEY` is ever unset in production, all PII (name, phone, email) is encrypted with `"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"`. | Remove the default. Use `ENV.fetch("ENCRYPTION_KEY")` without fallback so the app fails fast if the key is missing. Guard with an initializer that raises on boot if the key is absent in production. |
| C2 | `app/models/reservation.rb` | 3-5 | **Encryption key evaluated at class load time.** `attr_encrypted` reads `ENV.fetch(...)` when the class is loaded, not per-request. If the env var changes after boot (e.g., secret rotation), the old key is used until restart. More critically, constants are frozen into the class -- any change requires a full restart. | This is acceptable for most deployments but document that key rotation requires a rolling restart. |
| C3 | `app/services/sens_sms_service.rb` | 8-11 | **ENV vars captured as class-level constants at load time.** `SENS_ACCESS_KEY = ENV['SENS_ACCESS_KEY']` etc. are evaluated once when the class is loaded. In environments with lazy class loading or if secrets are injected after boot (e.g., some container orchestrators), these will be `nil` permanently. | Change to methods: `def self.access_key; ENV['SENS_ACCESS_KEY']; end` or read from `ENV` inside `send_sms`. |
| C4 | `app/controllers/reservations_controller.rb` | 26 | **IDOR vulnerability on `show` action.** Any unauthenticated user can view any reservation by guessing/incrementing the ID (`/reservations/1`, `/reservations/2`, etc.). Reservation contains PII (name, phone, email). | Add a token-based lookup (e.g., `find_by!(token: params[:token])` with a `SecureRandom.urlsafe_base64` token) or restrict access via session/cookie tied to the reservation. |
| C5 | No file | N/A | **No rate limiting on reservation creation.** The `POST /reservations` endpoint has no rate limiting. An attacker could spam thousands of reservations, triggering SMS/email floods (and incurring SENS API costs). | Add `Rack::Attack` or `rack-throttle` to limit reservation creation by IP (e.g., 5 per hour). |

### HIGH (Fix Before Next Release)

| # | File | Line | Issue | Recommended Action |
|---|------|------|-------|--------------------|
| H1 | `app/controllers/admin/reservations_controller.rb` | 5-13 | **N+1-like performance issue: 7 separate COUNT queries on every index load.** Each `Reservation.where(status: ...).count` fires a separate SQL query. With growing data, this becomes a bottleneck. | Use a single `GROUP BY` query: `Reservation.group(:status).count` and compute totals from the hash. For `today` and `this_week`, consider caching or a single combined query. |
| H2 | `app/models/reservation.rb` | 9 | **Phone validation regex mismatch with actual usage.** Model validates `\A\d{10,11}\z` (digits only), but `SensSmsService` (line 21) strips dashes/spaces with `gsub(/[-\s]/, '')`. Users who enter `010-1234-5678` will fail server-side validation even though the service handles it. | Either strip non-digits in a `before_validation` callback, or update the regex to allow dashes/spaces. |
| H3 | `app/views/admin/reservations/show.html.erb` | 65 | **XSS risk: unescaped user content.** `<%= @reservation.requests %>` outputs user-provided text. While Rails auto-escapes `<%= %>` by default, the `requests` field in a `<dd>` without `simple_format` or `sanitize` means newlines are ignored. More importantly, `selected_subjects` (line 54) are joined and output directly -- if an attacker manipulates the array values, they could inject content. | Explicitly use `sanitize()` or `h()` for user-generated content. Use `simple_format(h(@reservation.requests))` for proper newline handling. |
| H4 | `app/views/reservations/new.html.erb` + `_form_fields.html.erb` | All | **Massive code duplication.** The `new.html.erb` (407 lines) and `_form_fields.html.erb` (299 lines) contain nearly identical form markup (steps 1-9 are duplicated). Two copies of the privacy modal, two copies of the review step. | Remove one. The `new.html.erb` should render the `_form_fields` partial, or vice versa. Currently maintaining two copies means bugs fixed in one may not be fixed in the other. |
| H5 | `app/models/reservation.rb` | 101-102 | **`update_column` inside `after_create_commit` callback.** `schedule_reminder` calls `update_column(:reminder_job_id, ...)` which bypasses validations and callbacks. This is intentional for performance, but if the record was just created, the `after_create_commit` is already outside the transaction. However, there is a race condition: if two callbacks fire simultaneously (e.g., `send_notifications` and `schedule_reminder` both as `after_create_commit`), the `update_column` may conflict. | Consider using a single `after_create_commit` callback that handles both operations sequentially. |
| H6 | `app/jobs/sms_notification_job.rb` | 15 | **Fragile error classification.** `raise e unless e.message.include?("SENS API")` relies on error message string matching to decide retry behavior. If the error message format changes (e.g., localization, upstream API changes), legitimate transient errors will be swallowed. | Use a custom exception class (e.g., `SensConfigurationError`) raised from `SensSmsService` and rescue by class, not by message content. |
| H7 | `app/views/home/index.html.erb` | 1-585 | **Landing page is 585 lines in a single template.** Contains hero, tabs, curriculum, reviews, coach intro, pricing, CTA, and footer -- all in one file. Hard to maintain and violates single-responsibility. | Extract each section into partials: `_hero.html.erb`, `_curriculum.html.erb`, `_pricing.html.erb`, `_reviews.html.erb`, `_coach.html.erb`, `_cta.html.erb`. |

### MEDIUM (Improvement Recommended)

| # | File | Line | Issue | Recommended Action |
|---|------|------|-------|--------------------|
| M1 | `app/controllers/admin/reservations_controller.rb` | 41 | **No state machine for status transitions.** Any status can transition to any other status (pending -> completed, cancelled -> pending, etc.). No business logic guards invalid transitions. | Implement a state machine (e.g., `aasm` gem or manual guard) to enforce valid transitions: pending -> confirmed/cancelled, confirmed -> completed/cancelled, etc. |
| M2 | `app/mailers/reservation_mailer.rb` | 1-48 | **Repetitive boilerplate across all mailer methods.** Every method repeats the same 3 lines: `@reservation = reservation`, `@datetime = format_datetime(...)`, `@contact = ENV.fetch(...)`. | Extract a `before_action`-style setup or a private method that sets all instance variables, called from each action. |
| M3 | `app/controllers/admin/reservations_controller.rb` | 29-31 | **Notification sent even if only status changed (not datetime).** The `update` action checks `saved_change_to_reservation_datetime?` correctly, but the `update_status` action (line 46-48) sends notifications for every status change including back-and-forth toggling. No deduplication or cooldown. | Add a cooldown period or track last notification sent to prevent spam. |
| M4 | `app/javascript/controllers/step_form_controller.js` | 49, 178 | **Hardcoded step numbers.** `step === 10` for review and `this.currentStepValue === 9` for privacy check are magic numbers. If steps are added/removed, these break silently. | Use named constants or derive the step purpose from data attributes (e.g., `data-step-type="review"`, `data-step-type="privacy"`). |
| M5 | `app/javascript/controllers/step_form_controller.js` | 178 | **Step 9 privacy validation mismatch.** The `new.html.erb` has 10 steps (privacy at step 9, review at step 10), but `_form_fields.html.erb` has 9 steps (privacy at step 8, review at step 9). The hardcoded `=== 9` check in the controller will only work for one of these templates. | This is a direct consequence of the duplication in H4. Resolve H4 first. |
| M6 | `db/schema.rb` | 30-31 | **Plaintext columns coexist with encrypted columns.** `name`, `phone`, `email` are both plaintext NOT NULL columns AND have `encrypted_*` counterparts. The plaintext columns still have data (migration adds encrypted columns but does not remove originals). | After confirming encryption works, migrate data from plaintext to encrypted columns, then drop the plaintext `name`, `phone`, `email` columns to avoid storing PII unencrypted. |
| M7 | `app/models/reservation.rb` | 13 | **`privacy_agreed` acceptance validation may not work as expected with attr_encrypted.** The `acceptance` validator checks for truthiness, but `privacy_agreed` is a boolean DB column (not a virtual attribute). Rails `acceptance` is designed for virtual attributes. Since it is a real column, it works differently. | Test edge cases. Consider using `validates :privacy_agreed, inclusion: { in: [true] }` instead for clarity. |
| M8 | `app/controllers/admin/reservations_controller.rb` | 59-62 | **`send_sms` action has no CSRF confirmation beyond turbo_confirm.** While Devise protects admin routes and CSRF is enabled, the `send_sms` action triggers an external API call (SMS) with no audit trail or confirmation token. | Add an audit log for SMS sends. Consider adding a `last_sms_sent_at` timestamp to prevent accidental double-sends. |
| M9 | `app/javascript/controllers/stream_card_controller.js` | 85 | **DOM mutation via `textContent +=` in animation loop.** Each character append triggers a DOM reflow. For long text blocks, this causes layout thrashing. | Use `requestAnimationFrame` batching or build the string in memory and set `textContent` once per frame. |
| M10 | `config/routes.rb` | 15-21 | **Catch-all routes suppress legitimate 404s.** `/_stcore/*path`, `/favicon.ico`, and `/.well-known/*path` all return 200/204 silently. The `_stcore` route in particular looks like a Streamlit artifact that should not be in production. | Remove development-only routes or wrap in `if Rails.env.development?`. |

### LOW (Reference/Minor)

| # | File | Line | Issue | Recommended Action |
|---|------|------|-------|--------------------|
| L1 | `app/mailers/reservation_mailer.rb` | 39 | **Hardcoded fallback email.** `ENV.fetch("ADMIN_EMAIL", "iamblackwhite86@gmail.com")` exposes a real email address in source code. | Move to config/credentials or ensure `.env.example` documents this without a real address. |
| L2 | `app/views/home/index.html.erb` | 564-566 | **Real contact info and address in view template.** Phone number and physical address are hardcoded in the footer. | Move to a config constant or ENV var for easier updates. |
| L3 | `app/models/reservation.rb` | 21-74 | **Business data hardcoded in model.** Package pricing, coaching types, subject options, and status labels are all constants in the model. Changes require code deployment. | Acceptable for current scale, but consider moving to a YAML config file or database table if these change frequently. |
| L4 | `app/javascript/controllers/step_form_controller.js` | 84 | **Hardcoded price labels in JS.** `{ starter: "STARTER (49만원)", ... }` duplicates pricing from the Ruby model. Price changes require updating two files. | Consider rendering package labels as data attributes from the server. |
| L5 | `app/controllers/reservations_controller.rb` | 1-44 | **No logging for reservation creation.** Successful reservation creation has no server-side log entry for audit purposes. | Add `Rails.logger.info "Reservation ##{@reservation.id} created"` after successful save. |
| L6 | `app/views/admin/reservations/show.html.erb` | 6 | **Missing partial `_status_badge`.** The template references `admin/reservations/status_badge` but this file was not included in the review scope. Verify it exists and handles all status values. | Confirm the partial exists and renders correctly for all 4 statuses. |
| L7 | `app/javascript/controllers/scroll_reveal_controller.js` | 60 | **`setTimeout` without cleanup.** `setTimeout` calls in `revealElement` are not tracked or cancelled on disconnect. If elements are removed from the DOM before the timeout fires, the callback will fail silently or cause unexpected behavior. | Store timeout IDs and clear them in `disconnect()`. |

---

## Architecture Assessment

### Strengths
1. **Clean MVC separation.** Controllers are thin, model handles validation and callbacks, services encapsulate external API calls.
2. **Devise-based admin auth.** Admin routes are properly guarded behind `authenticate_admin_user!`.
3. **CSRF protection enabled.** `protect_from_forgery with: :exception` is set in `ApplicationController`.
4. **Async notification pattern.** SMS and email are dispatched via background jobs (Sidekiq), preventing slow user-facing requests.
5. **Encryption at rest.** PII fields use `attr_encrypted` for database-level encryption.
6. **Stimulus controllers are well-structured.** Proper `connect`/`disconnect` lifecycle management, event cleanup.

### Weaknesses
1. **No rate limiting anywhere.** Neither public nor admin endpoints have rate limiting.
2. **No test files found.** Zero test coverage observed in the reviewed files.
3. **IDOR on public reservation show page.** Sequential IDs expose all reservations.
4. **Template duplication.** Two near-identical copies of the multi-step form.
5. **No state machine for reservation status.** Any transition is allowed.

---

## Duplicate Code Analysis

### Duplicates Found
| Type | Location 1 | Location 2 | Similarity | Recommended Action |
|------|------------|------------|------------|-------------------|
| Exact | `app/views/reservations/new.html.erb` (steps 1-9, ~350 lines) | `app/views/reservations/_form_fields.html.erb` (steps 1-9, ~297 lines) | ~90% | Delete one, use the other as the single source |
| Structural | `app/mailers/reservation_mailer.rb` (5 mailer methods) | Same file | 80% (same 3-line setup) | Extract common setup method |
| Structural | `app/jobs/sms_notification_job.rb` (rescue block) | `app/jobs/email_notification_job.rb` (rescue block) | 70% | Extract shared error handling concern |

---

## Security Summary

| Check | Status | Notes |
|-------|--------|-------|
| SQL Injection | PASS | ActiveRecord parameterized queries used throughout |
| XSS | PASS (with caveat) | Rails auto-escaping active; recommend explicit `sanitize` for user content in admin views |
| CSRF | PASS | `protect_from_forgery` enabled, Turbo handles CSRF tokens |
| Authentication (Admin) | PASS | Devise with `before_action :authenticate_admin_user!` |
| Authorization (Public) | **FAIL** | IDOR on `ReservationsController#show` (C4) |
| Rate Limiting | **FAIL** | No rate limiting implemented (C5) |
| Secrets in Code | **FAIL** | Weak encryption key fallback (C1), real email in source (L1) |
| Input Validation | PASS | Server-side validations on all required fields |
| Error Messages | PASS | Error messages do not leak sensitive data |

---

## Performance Summary

| Check | Status | Notes |
|-------|--------|-------|
| N+1 Queries | **WARN** | 7 separate COUNT queries on admin index (H1) |
| Async Processing | PASS | Notifications dispatched via background jobs |
| Database Indexes | PASS | Indexes on `status`, `email`, `reservation_datetime`, `package` |
| Caching | WARN | No fragment caching on admin dashboard stats |
| Asset Optimization | PASS | Multi-stage Docker build, CSS/JS precompilation |

---

## Improvement Recommendations (Priority Order)

1. **[C1] Remove insecure encryption key fallback** -- Highest risk. Add an initializer that raises if `ENCRYPTION_KEY` is missing in production.
2. **[C4] Fix IDOR on reservation show** -- Add token-based access or session-scoped authorization.
3. **[C5] Add rate limiting** -- Install `Rack::Attack` and configure limits for reservation creation and SMS endpoints.
4. **[H1] Optimize admin index queries** -- Replace 7 COUNT queries with a single GROUP BY.
5. **[H4] Eliminate template duplication** -- Single source of truth for the multi-step form.
6. **[M6] Remove plaintext PII columns** -- After encryption migration is confirmed working, drop redundant plaintext columns.
7. **[M1] Implement status state machine** -- Enforce valid status transitions.
8. **[H2] Fix phone validation** -- Strip non-digits before validation to match user expectations.

---

## Deployment Readiness

```
CRITICAL issues found: 5
  -> Immediate fix recommended for C1 (encryption), C4 (IDOR), C5 (rate limiting)
  -> C3 (env var loading) should be fixed before production deployment
  -> Deployment NOT approved until C1, C4, and C5 are resolved
```

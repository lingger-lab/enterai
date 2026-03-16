# Code Analysis Results (v2 - Fresh Scan)

## Analysis Target
- Path: c:\workspace\enterai-main
- File count: 48 source files scanned
- Analysis date: 2026-03-16

## Quality Score: 78/100

---

## Issues Found

### CRITICAL (Immediate Fix Required)

| # | File | Line | Issue | Recommended Action |
|---|------|------|-------|-------------------|
| 1 | `app/controllers/reservations_controller.rb` | 25-28 | **IDOR timing attack on show action**: `Reservation.find(params[:id])` runs before the token check. If the ID doesn't exist, it raises `ActiveRecord::RecordNotFound` (404). If the ID exists but the token is wrong, it redirects (302). An attacker can enumerate valid reservation IDs by observing the different HTTP responses. | Use `find_by` and return the same response regardless of whether the record exists or the token is wrong. |
| 2 | `app/models/reservation.rb` | 3 | **ENCRYPTION_KEY is evaluated once at class load time and cached as a constant.** In non-production environments, `SecureRandom.hex(16)` generates a new key on every server restart. All previously encrypted data (name, phone, email) becomes permanently unreadable after restart. This will cause `OpenSSL::Cipher::CipherError` crashes when reading any existing reservation in development/staging. | Store the fallback key in a file (e.g., `tmp/encryption_key`) or use Rails credentials instead of generating a random key. |
| 3 | `app/models/reservation.rb` | 120-124 | **Race condition in `schedule_reminder`**: `update_column(:reminder_job_id, ...)` is called inside an `after_create_commit` callback. If the job enqueues before `update_column` completes, and the job runs immediately (fast Redis), it can attempt to find a reservation that hasn't finished its transaction yet. More critically, `job.provider_job_id` may be `nil` for some Active Job adapters (including inline/async), causing the `reminder_job_id` to never be stored, making `cancel_scheduled_reminder` unable to cancel old jobs. | Check `provider_job_id` availability explicitly. For non-Sidekiq adapters, log a warning instead of silently failing. |
| 4 | `app/controllers/admin/reservations_controller.rb` | 40-44 | **Status bypass via edit form**: The admin edit form (`edit.html.erb` line 40-41) allows directly changing the status via a `<select>` dropdown, which **bypasses** the `can_transition_to?` state machine check that is only enforced in `update_status`. An admin can set `completed -> pending` or any invalid transition through the edit form. | Either remove `:status` from `reservation_params` in the update action (force all status changes through `update_status`), or add the same `can_transition_to?` validation in a model-level `validate` callback. |
| 5 | `app/javascript/controllers/application.js` | 6 | **Stimulus debug mode enabled in production**: `application.debug = true` is hardcoded. In production, this dumps verbose Stimulus lifecycle logs to the browser console, leaking internal controller names and potentially slowing page interactions on low-end devices. | Set `application.debug = false` or conditionally enable based on environment (e.g., check a meta tag). |

### WARNING (Improvement Recommended)

| # | File | Line | Issue | Recommended Action |
|---|------|------|-------|-------------------|
| 6 | `app/models/reservation.rb` | 11 | **Phone validation regex allows dashes but JS validation rejects them.** Server-side regex `\A[\d\-]{10,13}\z` allows `010-1234-5678` (13 chars with dashes). Client-side JS regex in `step_form_controller.js:169` is `^\d{10,11}$` after stripping dashes. This mismatch means: a phone like `010-1234-56789` (14 chars with dashes, 12 digits) passes client validation but fails server validation, causing a confusing error only after submission. | Align the validation rules. Recommend stripping dashes server-side before validation and using the same digit-count rule (10-11 digits). |
| 7 | `app/views/admin/reservations/show.html.erb` | 63-66 | **XSS risk in requests display**: `@reservation.requests` is rendered without explicit escaping inside a `<dd>` tag. While ERB auto-escapes by default with `<%= %>`, the `requests` field is a free-text `<textarea>` input. If any future change introduces `raw` or `html_safe`, this becomes an XSS vector. The admin view also displays `name`, `phone`, `email` which are user-supplied encrypted fields. | Confirm all user-supplied fields use `<%= %>` (auto-escaped) and add a CSP `frame-ancestors: none` (already done). Consider using `sanitize()` for the requests field as defense-in-depth. |
| 8 | `app/mailers/reservation_mailer.rb` | 39 | **`admin_notification` raises at runtime if ADMIN_EMAIL is unset.** `ENV.fetch("ADMIN_EMAIL") { raise "ADMIN_EMAIL must be set" }` will crash the `EmailNotificationJob` worker. Since this is called inside a Sidekiq job, it will retry 25 times (default), flooding error logs. Meanwhile, the customer-facing `reservation_created` email was already sent successfully, so this failure is invisible to the user but noisy in monitoring. | Use a fallback email or gracefully skip admin notification when ADMIN_EMAIL is not configured, similar to how the SMS service handles missing config. |
| 9 | `app/controllers/admin/reservations_controller.rb` | 4-12 | **N+1 potential in admin index**: `Reservation.order(created_at: :desc)` loads all reservations, then the partial `_reservation.html.erb` calls `reservation.name`, `reservation.phone`, `reservation.email`. These are `attr_encrypted` virtual attributes that decrypt on access. While not a DB N+1, each row triggers 3 decryption operations. With 100+ reservations per page (pagy default 20), this is 60 decryptions per page load. | This is acceptable at current scale (20 per page) but monitor if page load degrades. Consider caching decrypted values in a request-scoped variable if needed. |
| 10 | `app/views/reservations/new.html.erb` | 379-405 | **Inline `<script>` tag accesses `window.Stimulus` which may not be ready.** The `DOMContentLoaded` listener tries to call `window.Stimulus.getControllerForElementAndIdentifier()`. With importmap + Turbo, `DOMContentLoaded` fires before ES modules finish loading, so `window.Stimulus` may be `undefined`. The `try/catch` silently swallows this, but the review-update-on-change feature quietly never works on first page load. | Move this logic into the Stimulus controller itself (e.g., listen to `change`/`input` events on the form via Stimulus `data-action` bindings) instead of relying on global script access. |
| 11 | `app/views/reservations/new.html.erb` | 392 | **Off-by-one in step check**: The inline script checks `controllerInstance.currentStepValue === 10` to trigger `updateReview()`. But Stimulus values are reactive -- when the value changes, the controller's `showStep()` already calls `updateReview()` at step 10 (line 49 of `step_form_controller.js`). This means the inline script's form change listener is redundant for the review step but dead code for all other steps. | Remove the inline script entirely. The Stimulus controller already handles review updates. If real-time updates are needed on step 10, add `data-action="input->step-form#updateReview"` to the form. |
| 12 | `config/initializers/content_security_policy.rb` | 9 | **CSP includes `unsafe_inline` for `script-src`**, which weakens XSS protection significantly. While a nonce generator is configured (line 15-16), `unsafe_inline` overrides nonce enforcement in most browsers. The inline `<script>` in `new.html.erb` is the reason this is needed. | Remove the inline script (see issue #11), then remove `:unsafe_inline` from `script-src` to properly enforce nonce-based CSP. |
| 13 | `app/models/reservation.rb` | 16 | **`acceptance` validation on `privacy_agreed` may cause issues with admin edit.** When an admin edits a reservation through the edit form, the `privacy_agreed` field is not included in the form. The `acceptance` validator treats a missing/blank value as "not accepted" and will fail validation. However, since `privacy_agreed` is not in admin's `reservation_params`, it won't be submitted, so the existing value persists. This is safe but fragile -- if anyone adds `privacy_agreed` to admin params, edits will fail. | Add a comment explaining this, or scope the validation: `validates :privacy_agreed, acceptance: {...}, on: :create`. |
| 14 | `app/controllers/admin/reservations_controller.rb` | 72 | **Admin can set arbitrary status via `reservation_params`**: The update action permits `:status` in params, allowing direct status changes without `can_transition_to?` validation. This is a duplicate path to issue #4 but worth noting separately as the permit list is the root cause. | Remove `:status` from `reservation_params` or add model-level transition validation. |

### INFO (Reference)

| # | Observation |
|---|-------------|
| 15 | `ApplicationMailer` is missing a `layout` declaration. Email templates are raw HTML without a shared layout, which works but makes styling changes require editing every template individually. |
| 16 | `config.time_zone` is not set in `application.rb` (line 24, commented out). All `Time.current` calls use UTC. Korean users see reservation times in UTC unless the browser converts them. The `strftime` calls in mailers and SMS will format in UTC, not KST. |
| 17 | The `Pagy::Backend` module is included in `Admin::BaseController` but `Pagy::Frontend` (for `pagy_nav` helper) is not explicitly included anywhere. This works because Rails auto-includes it in helpers, but it's implicit. |
| 18 | `app/views/reservations/_form_fields.html.erb` does not exist (Read returned error), yet it is listed in git status as modified. This is a git staging artifact -- the partial was likely deleted but the deletion wasn't staged. Not a runtime issue since no code references it. |
| 19 | `selected_subjects` is stored as a PostgreSQL array column. When no subjects are selected, the form submits nothing for this field, leaving it as the default `[]`. However, if a user submits with subjects then an admin edits without the hidden empty-array trick, unchecking all boxes sends no param, leaving the old value unchanged. The admin edit form (`edit.html.erb`) does not include a hidden field for empty array fallback. |
| 20 | `Reservation::COACHING_TYPES` includes "온라인 코칭" but the landing page and pricing section don't mention online coaching as an option. This could confuse users who select it during reservation. |

---

## Summary by Severity

| Severity | Count | Deployment Impact |
|----------|-------|-------------------|
| CRITICAL | 5 | Should fix before next deploy |
| WARNING | 9 | Fix recommended, deploy with caution |
| INFO | 6 | No deployment impact |

## Top 3 Recommended Actions

1. **Fix ENCRYPTION_KEY handling** (Issue #2) -- This will crash the app in dev/staging on every restart. Use Rails credentials or a file-persisted fallback key.

2. **Enforce state machine at model level** (Issues #4, #14) -- Add a `before_validation` callback that checks `can_transition_to?` when status changes, rather than relying on controller-level enforcement that can be bypassed.

3. **Remove inline script and tighten CSP** (Issues #10, #11, #12) -- The inline `<script>` in `new.html.erb` is redundant (Stimulus already handles it), forces `unsafe_inline` in CSP, and may not work reliably with Turbo/importmap.

---

## Architecture & Configuration Notes

- **Time zone**: All server-side times are UTC. Korean users will see UTC times in SMS/email notifications. Set `config.time_zone = "Seoul"` in `application.rb`.
- **Stimulus debug**: Hardcoded to `true` -- should be environment-conditional.
- **CSP nonce**: Configured but nullified by `unsafe_inline` -- fix after removing inline scripts.
- **No test files found**: Zero test coverage detected. Consider adding at minimum: model validation tests, controller integration tests for the reservation flow, and a job test for notification dispatch.

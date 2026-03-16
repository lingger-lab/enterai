# Security Scan v2 - EnterLab AI Coaching Reservation System

**Date**: 2026-03-16
**Scan Type**: Second-pass comprehensive review (post-remediation)
**Stack**: Rails 8.0, PostgreSQL, Sidekiq, Devise, SendGrid, Naver SENS, attr_encrypted, rack-attack
**Auditor**: Security Architect Agent

---

## Executive Summary

The first scan identified 2 critical and 4 high issues. Most have been successfully remediated: IDOR is fixed with access tokens, encryption key fallback is improved, rack-attack rate limiting is in place, lockable is enabled on admin accounts, and plaintext PII columns are removed.

This second pass found **0 critical**, **3 high**, **5 medium**, and **4 low** severity issues that remain or were newly introduced.

| Severity | Count | Status |
|----------|-------|--------|
| CRITICAL | 0 | -- |
| HIGH | 3 | Fix before release |
| MEDIUM | 5 | Fix in next sprint |
| LOW | 4 | Track in backlog |

---

## HIGH Severity Findings

### H-01: `coaching_type` Lacks Inclusion Validation (A03 - Injection / A04 - Insecure Design)

**File**: `app/models/reservation.rb:14`
**Current code**:
```ruby
validates :coaching_type, presence: true
```

**Issue**: `coaching_type` is validated for presence only, but not constrained to the allowed `COACHING_TYPES` list. An attacker can submit any arbitrary string as the coaching type. This value is then rendered unescaped in SMS messages (`sms_notification_job.rb:34`) and embedded in emails. While Rails ERB auto-escapes HTML, the SMS channel has no escaping, and arbitrary values pollute data integrity.

**Impact**: Data integrity violation, potential social engineering via crafted SMS content.

**Fix**:
```ruby
validates :coaching_type, presence: true, inclusion: { in: COACHING_TYPES }
```

---

### H-02: `selected_subjects` Array Accepts Arbitrary Values (A03 - Injection / A04 - Insecure Design)

**File**: `app/models/reservation.rb` (missing validation), `app/controllers/reservations_controller.rb:43`

**Issue**: The `selected_subjects` array is permitted via strong params but has no server-side validation restricting values to `SUBJECT_OPTIONS`. An attacker can POST any strings into this array. These values are then rendered in admin views, emails, and SMS messages.

**Impact**: Stored arbitrary content rendered in admin interface and notification channels.

**Fix**: Add a custom validation to the Reservation model:
```ruby
validate :valid_selected_subjects

def valid_selected_subjects
  return if selected_subjects.blank?
  invalid = selected_subjects - SUBJECT_OPTIONS
  errors.add(:selected_subjects, "contains invalid options") if invalid.any?
end
```

---

### H-03: `.env` File Contains Real Credentials and Is Tracked by Git (A02 - Cryptographic Failures / A05 - Security Misconfiguration)

**File**: `.env` (root directory)

**Issue**: The `.env` file exists in the working directory and contains:
- `DATABASE_PASSWORD=8590`
- `ADMIN_PASSWORD=enterlab2026!`
- `ENCRYPTION_KEY=abcdefghijklmnopqrstuvwxyz123456`
- `SENS_SENDER_NUMBER=010-5529-1912` (real phone number)

While `.gitignore` includes `/.env`, the git status shows the file exists locally. If `.gitignore` was added after the file was tracked, or if an operator mistakenly commits it, these credentials are permanently exposed. Additionally, `ADMIN_PASSWORD` is stored in `.env` but there is no seed file or initializer that uses it -- this suggests it may be used manually, but its presence in `.env` creates a risk of accidental exposure.

The `ENCRYPTION_KEY` value (`abcdefghijklmnopqrstuvwxyz123456`) is a weak, predictable key that should never be used even in development, as it could accidentally propagate to production.

**Impact**: Credential exposure risk. Weak encryption key if used in any non-development context.

**Fix**:
1. Verify `.env` is not tracked: `git ls-files .env` should return empty
2. Replace `ENCRYPTION_KEY` with a cryptographically random value even for dev: `SecureRandom.hex(16)`
3. Remove `ADMIN_PASSWORD` from `.env` -- use Rails credentials or a seed task with environment checks
4. Add `.env.example` with placeholder values and no real secrets

---

## MEDIUM Severity Findings

### M-01: Devise Paranoid Mode Disabled (A07 - Identification and Authentication Failures)

**File**: `config/initializers/devise.rb:93`

**Current**: `# config.paranoid = true` (commented out)

**Issue**: When paranoid mode is off, Devise reveals whether an email exists in the system during password recovery and sign-in attempts. This enables user enumeration attacks against the admin login.

**Fix**: Uncomment and enable: `config.paranoid = true`

---

### M-02: Admin Session Has No Timeout (A07 - Identification and Authentication Failures)

**File**: `config/initializers/devise.rb:191`, `app/models/admin_user.rb:2`

**Issue**: The `AdminUser` model does not include `:timeoutable`, and `config.timeout_in` is commented out. Admin sessions remain active indefinitely once created. If an admin leaves their browser open on a shared or stolen device, the session persists.

**Fix**:
```ruby
# admin_user.rb
devise :database_authenticatable, :rememberable, :validatable, :lockable, :timeoutable

# devise.rb
config.timeout_in = 30.minutes
```

---

### M-03: CSP Allows `unsafe-inline` for Scripts (A05 - Security Misconfiguration)

**File**: `config/initializers/content_security_policy.rb:9`

**Current**:
```ruby
policy.script_src :self, :unsafe_inline
```

**Issue**: The CSP uses a nonce generator (line 15-16), which is good. However, `unsafe-inline` is also included, which completely negates the nonce requirement. Any inline script injected via an XSS vector would execute. The `new.html.erb` reservation form includes an inline `<script>` block (lines 379-406) that relies on `unsafe-inline`.

**Impact**: Reduced XSS mitigation from CSP.

**Fix**: Refactor the inline script in `new.html.erb` into the Stimulus controller (it already overlaps with `step_form_controller.js`), then remove `unsafe-inline` from the CSP and rely solely on nonces.

---

### M-04: `docker-compose.yml` Contains Hardcoded SECRET_KEY_BASE (A05 - Security Misconfiguration)

**File**: `docker-compose.yml:35,51`

```yaml
SECRET_KEY_BASE: local_dev_secret_key_base_replace_in_production
```

**Issue**: While labeled as "replace in production", this is a common source of production misconfiguration. If this docker-compose file is used as a template for deployment, the weak secret key base could be carried over.

**Fix**: Use environment variable interpolation: `SECRET_KEY_BASE: ${SECRET_KEY_BASE}` and document that it must be set externally.

---

### M-05: Access Token Comparison Vulnerable to Timing Attack (A02 - Cryptographic Failures)

**File**: `app/controllers/reservations_controller.rb:26`

```ruby
unless @reservation.access_token.present? && params[:token] == @reservation.access_token
```

**Issue**: The `==` string comparison is not constant-time. An attacker could theoretically use timing differences to brute-force the access token character by character. While the 32-byte `urlsafe_base64` token has high entropy (256 bits), defense-in-depth dictates using constant-time comparison.

**Fix**:
```ruby
unless @reservation.access_token.present? &&
       ActiveSupport::SecurityUtils.secure_compare(params[:token].to_s, @reservation.access_token)
```

---

## LOW Severity Findings

### L-01: Reservation Show Page Exposes Full PII After Creation (A01 - Broken Access Control)

**Files**: `app/views/reservations/show.html.erb`, `app/views/reservations/_success.html.erb`

**Issue**: After creating a reservation, the user is redirected to the show page which displays full name, phone number, and email in cleartext. The success partial also shows full PII. While the access token protects against unauthorized access, anyone who obtains the URL (e.g., from browser history, shared screen, or shoulder surfing) sees all PII.

**Recommendation**: Mask phone (e.g., `010-****-1234`) and email (e.g., `h***@email.com`) in the public-facing show view. The success turbo_stream partial could also mask these.

---

### L-02: No `Referrer-Policy` or `Permissions-Policy` Headers (A05 - Security Misconfiguration)

**File**: `config/environments/production.rb`, `config/initializers/content_security_policy.rb`

**Issue**: The application sets CSP and HSTS (via `force_ssl`), but does not configure `Referrer-Policy` or `Permissions-Policy` headers. The default browser behavior may leak the full URL (including access tokens in query params) to third-party resources.

**Fix**: Add to production config or via middleware:
```ruby
config.action_dispatch.default_headers.merge!(
  'Referrer-Policy' => 'strict-origin-when-cross-origin',
  'Permissions-Policy' => 'camera=(), microphone=(), geolocation=()'
)
```

---

### L-03: Access Token Passed as Query Parameter (A02 - Cryptographic Failures)

**File**: `app/controllers/reservations_controller.rb:12`

```ruby
redirect_to reservation_path(@reservation, token: @reservation.access_token)
```

**Issue**: The access token is passed as a URL query parameter (`?token=xxx`). Query parameters are logged in web server access logs, browser history, and can be leaked via the `Referer` header. This is mitigated by CSP `frame_ancestors: :none` and `force_ssl`, but remains a defense-in-depth concern.

**Recommendation**: Consider using a session-based approach or setting the token in a short-lived cookie after creation, rather than exposing it in the URL.

---

### L-04: Inline Script in `new.html.erb` Contains `console.log` (A09 - Security Logging Failures)

**File**: `app/views/reservations/new.html.erb:397`

```javascript
console.log("Controller not ready yet", e)
```

**Issue**: A `console.log` statement in production code that could leak internal controller state to browser developer tools.

**Fix**: Remove the `console.log` or replace with a no-op in production.

---

## Previously Fixed Issues (Confirmed Resolved)

| Previous Finding | Status |
|-----------------|--------|
| Hardcoded encryption key fallback | FIXED - now uses `ENV.fetch` with dev-only `SecureRandom` |
| IDOR via sequential IDs | FIXED - access tokens with unique index |
| No rate limiting | FIXED - rack-attack on reservation create and admin login |
| No account lockout | FIXED - Devise lockable enabled (5 attempts, 30min) |
| Plaintext PII columns | FIXED - removed via migration |
| Missing CSP | FIXED - CSP configured (though `unsafe-inline` remains, see M-03) |

---

## Recommendations Priority Matrix

| Priority | Finding | Effort | Impact |
|----------|---------|--------|--------|
| 1 | H-01: coaching_type validation | 5 min | Prevents data pollution |
| 2 | H-02: selected_subjects validation | 10 min | Prevents stored arbitrary content |
| 3 | H-03: .env credential hygiene | 15 min | Prevents credential leak |
| 4 | M-01: Devise paranoid mode | 1 min | Prevents user enumeration |
| 5 | M-02: Admin session timeout | 2 min | Prevents session hijacking |
| 6 | M-05: Timing-safe token compare | 2 min | Defense in depth |
| 7 | M-03: Remove CSP unsafe-inline | 30 min | Strengthens XSS defense |
| 8 | M-04: docker-compose secrets | 5 min | Prevents misconfiguration |
| 9 | L-02: Security headers | 5 min | Defense in depth |
| 10 | L-04: Remove console.log | 1 min | Information hygiene |
| 11 | L-01: Mask PII in show view | 15 min | Privacy improvement |
| 12 | L-03: Token in query param | 1 hr | Architecture improvement |

---

## Positive Security Observations

1. **CSRF protection** is properly enabled (`protect_from_forgery with: :exception`)
2. **PII encryption** via attr_encrypted is correctly implemented
3. **Strong params** are used consistently in all controllers
4. **Admin authentication** via Devise with lockable module
5. **Rate limiting** on both public endpoints and admin login (including per-email throttle)
6. **Docker** runs as non-root user with multi-stage build
7. **SSL enforcement** in production (`force_ssl = true`)
8. **No `raw` or `html_safe`** calls found anywhere in templates (XSS safe)
9. **Error messages** in jobs do not leak PII (phone is masked in SMS service)
10. **Sidekiq Web UI** is not mounted in routes (no unauthenticated queue dashboard)

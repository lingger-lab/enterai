# Security Review Report: EnterLab AI Coaching Reservation System

**Date**: 2026-03-16
**Reviewer**: Security Architect Agent
**Application**: EnterLab AI Coaching Reservation System (Rails 8.0)
**Scope**: Full OWASP Top 10 review, authentication, secrets management, infrastructure

---

## Executive Summary

The application has **2 Critical**, **4 High**, **5 Medium**, and **3 Low** severity findings. The most urgent issues are the hardcoded encryption key fallback in `reservation.rb` and the IDOR vulnerability on the public reservation show endpoint. Rate limiting is entirely absent, leaving the system vulnerable to abuse and spam reservations.

| Severity | Count | Status |
|----------|-------|--------|
| Critical | 2 | Block deployment |
| High | 4 | Fix before release |
| Medium | 5 | Fix in next sprint |
| Low | 3 | Track in backlog |

---

## Critical Findings

### C-1. Hardcoded Encryption Key Fallback (A02: Cryptographic Failures)

**File**: `app/models/reservation.rb:3-5`

```ruby
attr_encrypted :name, key: ENV.fetch("ENCRYPTION_KEY", "a" * 32)
attr_encrypted :phone, key: ENV.fetch("ENCRYPTION_KEY", "a" * 32)
attr_encrypted :email, key: ENV.fetch("ENCRYPTION_KEY", "a" * 32)
```

**Impact**: If `ENCRYPTION_KEY` is not set in the environment, the application silently falls back to `"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"` -- a trivially guessable 32-character key. All PII (names, phone numbers, emails) encrypted with this key can be decrypted by anyone with database access.

**Risk**: Complete compromise of all customer PII. Regulatory violation (Korean PIPA).

**Remediation**:
```ruby
attr_encrypted :name, key: ENV.fetch("ENCRYPTION_KEY")
attr_encrypted :phone, key: ENV.fetch("ENCRYPTION_KEY")
attr_encrypted :email, key: ENV.fetch("ENCRYPTION_KEY")
```

Remove the fallback entirely. `ENV.fetch` without a default will raise `KeyError` at boot if the variable is missing, which is the correct behavior -- the application should refuse to start without a proper encryption key.

Additionally, validate key strength at boot time:

```ruby
# config/initializers/encryption_check.rb
key = ENV.fetch("ENCRYPTION_KEY")
if key.length < 32 || key.chars.uniq.length < 8
  raise "ENCRYPTION_KEY is too weak. Use a cryptographically random 32-byte key."
end
```

---

### C-2. Insecure Direct Object Reference on Public Reservation Show (A01: Broken Access Control)

**File**: `app/controllers/reservations_controller.rb:25-27`

```ruby
def show
  @reservation = Reservation.find(params[:id])
end
```

**Route**: `GET /reservations/:id` (public, no authentication)

**Impact**: Anyone can view any reservation's PII (name, phone, email, schedule) by guessing or iterating sequential integer IDs. The `show.html.erb` template displays all decrypted PII fields. Since Rails uses auto-incrementing integer IDs by default, an attacker can enumerate all reservations trivially (`/reservations/1`, `/reservations/2`, ...).

**Risk**: Mass PII exposure. Automated scraping of all customer data.

**Remediation** (choose one or combine):

**Option A** -- Use UUID or token for public access:
```ruby
# migration
add_column :reservations, :confirmation_token, :string, null: false
add_index :reservations, :confirmation_token, unique: true

# model
before_create :generate_confirmation_token
def generate_confirmation_token
  self.confirmation_token = SecureRandom.urlsafe_base64(32)
end

# controller
def show
  @reservation = Reservation.find_by!(confirmation_token: params[:id])
end

# route
resources :reservations, only: [:new, :create, :show], param: :confirmation_token
```

**Option B** -- Remove public show entirely, send confirmation details via email/SMS only.

---

## High Findings

### H-1. No Rate Limiting (A05: Security Misconfiguration)

**Affected**: All endpoints, especially `POST /reservations` (public)

**Impact**: Without rate limiting, an attacker can:
- Submit thousands of spam reservations
- Trigger thousands of SMS/email notifications (costing real money via SendGrid and Naver SENS)
- Perform brute-force attacks against the admin login
- Cause denial of service

**Remediation**: Add `rack-attack` gem:

```ruby
# Gemfile
gem "rack-attack"

# config/initializers/rack_attack.rb
Rack::Attack.throttle("reservations/create/ip", limit: 5, period: 1.hour) do |req|
  req.ip if req.path == "/reservations" && req.post?
end

Rack::Attack.throttle("admin/login/ip", limit: 10, period: 15.minutes) do |req|
  req.ip if req.path.start_with?("/admin/sign_in") && req.post?
end

Rack::Attack.throttle("admin/login/email", limit: 5, period: 15.minutes) do |req|
  if req.path.start_with?("/admin/sign_in") && req.post?
    req.params.dig("admin_user", "email")&.downcase&.strip
  end
end
```

---

### H-2. SSL Not Enforced in Production (A02: Cryptographic Failures)

**File**: `config/environments/production.rb:46`

```ruby
# config.force_ssl = true  # COMMENTED OUT
```

**Impact**: All traffic including admin credentials, session cookies, and PII can be intercepted via man-in-the-middle attacks. While Google Cloud Run terminates TLS at the load balancer, `force_ssl` also sets `Strict-Transport-Security` headers and marks cookies as `Secure`, which are essential protections.

**Remediation**:
```ruby
config.force_ssl = true
```

---

### H-3. Admin Account Lockout Not Enabled (A07: Authentication Failures)

**File**: `config/initializers/devise.rb:193-213` (all lockable config commented out)

**Impact**: Unlimited login attempts against the admin panel. Combined with no rate limiting (H-1), this allows unlimited brute-force attacks.

**Remediation**: Enable Devise lockable module:

```ruby
# In AdminUser model
devise :database_authenticatable, :recoverable, :rememberable, :validatable, :lockable

# In devise.rb
config.lock_strategy = :failed_attempts
config.unlock_strategy = :time
config.maximum_attempts = 5
config.unlock_in = 30.minutes
```

Requires adding lockable columns to `admin_users` table.

---

### H-4. Hardcoded Admin Email Fallback (A02: Cryptographic Failures / Sensitive Data Exposure)

**File**: `app/mailers/reservation_mailer.rb:39`

```ruby
admin_email = ENV.fetch("ADMIN_EMAIL", "iamblackwhite86@gmail.com")
```

Also in: `app/views/home/index.html.erb:565`, `app/views/home/privacy_policy.html.erb:48`

**Impact**: A personal email address is hardcoded in source code (committed to git). This is a minor data leak and a code smell -- if the environment variable is not set, admin notifications go to a potentially unmonitored personal address.

**Remediation**: Remove the fallback. Require `ADMIN_EMAIL` to be set:

```ruby
admin_email = ENV.fetch("ADMIN_EMAIL")
```

For the view templates, use a helper or environment variable without exposing a hardcoded fallback in source code.

---

## Medium Findings

### M-1. No Security Headers Configured (A05: Security Misconfiguration)

**Affected**: All responses

The application does not configure:
- `Content-Security-Policy` (CSP) -- `csp_meta_tag` is present in the layout but no CSP policy is defined in an initializer
- `X-Frame-Options` -- Rails default `SAMEORIGIN` is likely active but should be verified
- `X-Content-Type-Options` -- Rails default `nosniff` is likely active
- `Strict-Transport-Security` -- Not set because `force_ssl` is disabled
- `Referrer-Policy`
- `Permissions-Policy`

**Remediation**: Create `config/initializers/content_security_policy.rb` with an appropriate CSP. Enable `force_ssl` (see H-2).

---

### M-2. SENS API Keys Loaded at Class Level (A05: Security Misconfiguration)

**File**: `app/services/sens_sms_service.rb:8-11`

```ruby
SENS_ACCESS_KEY = ENV['SENS_ACCESS_KEY']
SENS_SECRET_KEY = ENV['SENS_SECRET_KEY']
SENS_SERVICE_ID = ENV['SENS_SERVICE_ID']
SENS_SENDER_NUMBER = ENV['SENS_SENDER_NUMBER']
```

**Impact**: Constants are evaluated once at class load time. If environment variables are set after the class loads (e.g., via dotenv lazy loading, or if the class is eager-loaded before env vars are available), the constants will be `nil`. The guard clause handles this gracefully but it is a fragile pattern. More importantly, secrets stored in Ruby constants can be inspected at runtime via `SensSmsService::SENS_SECRET_KEY`.

**Remediation**: Use methods instead of constants:

```ruby
def self.access_key = ENV["SENS_ACCESS_KEY"]
def self.secret_key = ENV["SENS_SECRET_KEY"]
```

---

### M-3. Phone Number Logged in Plaintext (A09: Security Logging and Monitoring Failures)

**File**: `app/services/sens_sms_service.rb:51`

```ruby
Rails.logger.info "SMS sent to #{formatted_phone}: #{result['requestId']}"
```

**Impact**: Phone numbers (PII) are written to logs in plaintext. If logs are stored in Cloud Logging or exported to a third-party system, this expands the PII surface area beyond the encrypted database.

**Remediation**: Mask the phone number in logs:

```ruby
masked = formatted_phone.gsub(/(\d{3})\d{4}(\d{4})/, '\1****\2')
Rails.logger.info "SMS sent to #{masked}: #{result['requestId']}"
```

---

### M-4. No Input Length Validation on `requests` Field (A03: Injection)

**File**: `app/models/reservation.rb`

The `requests` text field has no length validation. An attacker could submit megabytes of text, causing:
- Database storage abuse
- Potential denial of service on admin list views
- SMS/email content overflow

**Remediation**:
```ruby
validates :requests, length: { maximum: 2000 }
```

---

### M-5. Schema Has Both Plaintext and Encrypted PII Columns (A02: Cryptographic Failures)

**File**: `db/schema.rb:30-33` and `db/schema.rb:40-45`

```ruby
t.string "name", null: false          # plaintext column
t.text "encrypted_name"               # encrypted column
```

Both plaintext and encrypted columns exist for `name`, `phone`, and `email`. If `attr_encrypted` is writing to the encrypted columns but the plaintext columns still contain data (from before encryption was added), PII exists unencrypted in the database.

**Impact**: Encryption is defeated if plaintext columns are populated.

**Remediation**:
1. Verify that `attr_encrypted` is configured to use `encrypted_*` columns (it should be by default)
2. Run a data migration to NULL out the plaintext columns: `UPDATE reservations SET name = NULL, phone = NULL, email = NULL;`
3. After confirming encrypted columns work, drop the plaintext `name`, `phone`, `email` columns or at minimum remove `null: false` and set them to NULL

---

## Low Findings

### L-1. No CAPTCHA or Bot Protection on Reservation Form

**Affected**: `POST /reservations`

The public reservation form has no CAPTCHA, honeypot field, or other bot detection. Combined with no rate limiting, automated spam submissions are trivial.

**Remediation**: Add reCAPTCHA, hCaptcha, or a honeypot field.

---

### L-2. Sidekiq Web UI Not Mentioned in Routes

**File**: `config/routes.rb`

Sidekiq ships with a web dashboard at `/sidekiq`. While it is not mounted in routes (good), ensure it is not accidentally mounted via an initializer or engine. If it ever gets mounted, it must be behind authentication.

**Remediation**: Verify no Sidekiq web mount exists. If needed in the future, protect it:

```ruby
require "sidekiq/web"
authenticate :admin_user do
  mount Sidekiq::Web => "/admin/sidekiq"
end
```

---

### L-3. `console.log` Statement in Production JavaScript

**File**: `app/views/reservations/new.html.erb:397`

```javascript
console.log("Controller not ready yet", e)
```

**Impact**: Minor information leak. Stack trace details visible in browser console.

**Remediation**: Remove or wrap in a development-only check.

---

## OWASP Top 10 Coverage Summary

| # | Category | Status | Findings |
|---|----------|--------|----------|
| A01 | Broken Access Control | FAIL | C-2 (IDOR on reservation show) |
| A02 | Cryptographic Failures | FAIL | C-1 (weak encryption key), H-2 (no SSL), H-4 (hardcoded email), M-5 (dual columns) |
| A03 | Injection | PASS (with note) | Rails uses parameterized queries by default. M-4 (unbounded input length) |
| A04 | Insecure Design | WARN | No CAPTCHA (L-1), sequential IDs expose enumeration surface |
| A05 | Security Misconfiguration | FAIL | H-1 (no rate limiting), M-1 (no security headers), M-2 (class-level secrets) |
| A06 | Vulnerable Components | WARN | `attr_encrypted` gem is unmaintained (last release 2019). Consider migrating to Rails 7+ built-in encryption (`encrypts` API) |
| A07 | Auth Failures | FAIL | H-3 (no account lockout) |
| A08 | Software Integrity | PASS | Gemfile.lock pinned, Docker multi-stage build |
| A09 | Logging Failures | WARN | M-3 (PII in logs). No audit logging for admin actions |
| A10 | SSRF | PASS | No user-controllable URL fetching |

---

## Prioritized Remediation Plan

### Phase 1: Immediate (Block Deployment)

| # | Finding | Effort | Impact |
|---|---------|--------|--------|
| C-1 | Remove encryption key fallback | 5 min | Prevents trivial PII decryption |
| C-2 | Fix IDOR on reservation show | 1-2 hours | Prevents PII enumeration |

### Phase 2: Before Release

| # | Finding | Effort | Impact |
|---|---------|--------|--------|
| H-1 | Add rack-attack rate limiting | 1-2 hours | Prevents spam, brute force, cost abuse |
| H-2 | Enable force_ssl | 5 min | HSTS headers, secure cookies |
| H-3 | Enable Devise lockable | 30 min | Brute force protection on admin |
| H-4 | Remove hardcoded admin email | 15 min | Clean secrets management |

### Phase 3: Next Sprint

| # | Finding | Effort | Impact |
|---|---------|--------|--------|
| M-1 | Configure security headers (CSP) | 1-2 hours | Defense in depth |
| M-2 | Refactor SENS service constants | 15 min | Robustness |
| M-3 | Mask PII in logs | 15 min | Compliance |
| M-4 | Add length validation on requests | 5 min | DoS prevention |
| M-5 | Clean up plaintext PII columns | 1 hour | Complete encryption |

### Phase 4: Backlog

| # | Finding | Effort | Impact |
|---|---------|--------|--------|
| L-1 | Add CAPTCHA | 1-2 hours | Bot protection |
| L-2 | Protect Sidekiq web UI | 15 min | Preventative |
| L-3 | Remove console.log | 5 min | Minor info leak |
| -- | Migrate from attr_encrypted to Rails encrypts | 2-4 hours | Maintained crypto |
| -- | Add admin action audit logging | 2-4 hours | Compliance, forensics |

---

## Positive Security Observations

1. **CSRF protection** is enabled globally via `protect_from_forgery with: :exception`
2. **Strong parameter filtering** is properly implemented in both controllers
3. **Devise authentication** is correctly enforced on all admin routes via `Admin::BaseController`
4. **PII encryption at rest** is implemented (though key management needs fixing)
5. **Input validation** exists on model level for required fields, email format, phone format
6. **Non-root Docker user** -- the Dockerfile correctly switches to a non-root `rails` user
7. **Environment variables** are used for all external service credentials (SendGrid, SENS, Redis)
8. **ERB auto-escaping** prevents XSS by default in all view templates
9. **`.env` files are gitignored** correctly
10. **Multi-stage Docker build** reduces attack surface in the runtime image

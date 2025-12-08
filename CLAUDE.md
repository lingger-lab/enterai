# CLAUDE.md - AI Assistant Guide for Enter.ai

> **Last Updated:** 2025-12-08
> **Project:** Enter.ai - AI Coaching Reservation System
> **Framework:** Ruby on Rails 8.0.4
> **Language:** Korean (UI, docs, comments)

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Technology Stack & Architecture](#technology-stack--architecture)
3. [Codebase Structure](#codebase-structure)
4. [Development Workflows](#development-workflows)
5. [Key Conventions & Patterns](#key-conventions--patterns)
6. [Security & Privacy](#security--privacy)
7. [Testing Strategy](#testing-strategy)
8. [Environment Configuration](#environment-configuration)
9. [Common Tasks & Commands](#common-tasks--commands)
10. [Important Files Reference](#important-files-reference)
11. [Gotchas & Known Issues](#gotchas--known-issues)
12. [AI Assistant Guidelines](#ai-assistant-guidelines)

---

## Project Overview

### Purpose
Enter.ai is a **Korean domestic AI coaching reservation platform** that enables users to schedule 1:1 AI coaching sessions with automated email and SMS notifications using Korean-based communication services.

### Key Features
- **Booking Form:** Comprehensive reservation form with name, contact, email, datetime, coaching type, subjects, requests, and privacy consent
- **Auto Notifications:** Async email (SendGrid) and SMS (Naver Cloud SENS) to users and admins
- **PII Encryption:** Field-level encryption for personal data (name, phone, email)
- **Modern UI:** Tailwind CSS with Hotwire (Turbo + Stimulus)
- **Background Jobs:** Sidekiq for async processing

### Project Status
- **Current State:** Initial commit complete - fully functional baseline implementation
- **Development Stage:** Ready for testing, feature expansion, and staging deployment
- **Testing:** No automated test suite yet (manual testing only)

### Important Context
- **Primary Language:** All UI, documentation, and code comments are in **Korean**
- **Domestic Stack:** Uses **Naver Cloud SENS** for SMS (not Twilio) - Korean domestic service only
- **Phone Format:** Korean phone numbers only (10-11 digits, country code 82)

---

## Technology Stack & Architecture

### Backend
| Technology | Version | Purpose |
|------------|---------|---------|
| Ruby | 3.3.10 | Runtime language |
| Rails | 8.0.4 | Web framework |
| PostgreSQL | 1.5+ | Primary database |
| Puma | 6.0+ | Application server |
| Sidekiq | 7.0 | Background job processing (requires Redis) |

### Frontend
| Technology | Version | Purpose |
|------------|---------|---------|
| Tailwind CSS | 3.4.0 | Utility-first styling |
| Hotwire Turbo | 8.0.0 | SPA-like navigation without page reloads |
| Stimulus | 3.2.1 | Lightweight JavaScript framework |
| Importmap Rails | - | JS module management (no bundler) |
| Propshaft | 1.3 | Modern Rails 8 asset pipeline |

### External Services
| Service | Purpose | API Method |
|---------|---------|------------|
| SendGrid | Email delivery | REST API (sendgrid-ruby gem) |
| Naver Cloud SENS | SMS delivery (Korean domestic) | REST API (rest-client gem) |

### Security & Utilities
- **attr_encrypted 4.0** - Transparent field-level encryption for PII
- **Devise 4.9** - Authentication framework (prepared for future admin features)
- **dotenv-rails** - Environment variable management

### Architecture Pattern
- **MVC:** Standard Rails Model-View-Controller
- **Service Objects:** External API integrations encapsulated in `/app/services/`
- **Background Jobs:** ActiveJob with Sidekiq adapter for async operations
- **RESTful Routes:** Simplified resource routing (new, create, show only)

---

## Codebase Structure

```
/home/user/enterai/
├── app/
│   ├── assets/
│   │   ├── stylesheets/
│   │   │   ├── application.tailwind.css      # Tailwind directives
│   │   │   └── application.css               # Compiled output
│   │   └── builds/                           # CSS build artifacts (gitignored)
│   ├── controllers/
│   │   ├── application_controller.rb         # Base controller
│   │   ├── home_controller.rb                # Landing page
│   │   └── reservations_controller.rb        # Booking logic (new/create/show)
│   ├── models/
│   │   └── reservation.rb                    # Core model with encryption & validations
│   ├── views/
│   │   ├── layouts/
│   │   │   └── application.html.erb          # Master layout with navigation
│   │   ├── home/
│   │   │   └── index.html.erb                # Landing page (hero, features)
│   │   ├── reservations/
│   │   │   ├── new.html.erb                  # Booking form
│   │   │   ├── show.html.erb                 # Confirmation page
│   │   │   └── create.turbo_stream.erb       # Loading animation
│   │   └── reservation_mailer/
│   │       ├── confirmation.{html,text}.erb  # User email templates
│   │       └── admin_notification.{html,text}.erb # Admin email templates
│   ├── mailers/
│   │   ├── application_mailer.rb             # Base mailer (SendGrid config)
│   │   └── reservation_mailer.rb             # Confirmation & admin emails
│   ├── jobs/
│   │   └── sms_notification_job.rb           # Async SMS via SENS
│   ├── services/
│   │   └── sens_sms_service.rb               # Naver Cloud SENS wrapper
│   └── javascript/
│       ├── application.js                    # Turbo + Stimulus loader
│       └── controllers/
│           ├── application.js                # Base Stimulus controller
│           └── index.js                      # Auto-loader
├── config/
│   ├── routes.rb                             # URL routing (RESTful)
│   ├── database.yml                          # PostgreSQL config
│   ├── application.rb                        # Rails core config
│   ├── tailwind.config.js                    # Tailwind customization
│   ├── importmap.rb                          # JS import mapping
│   ├── environments/
│   │   ├── development.rb                    # Dev settings (SMTP, caching)
│   │   ├── production.rb                     # Prod settings (Sidekiq adapter)
│   │   └── test.rb                           # Test environment
│   └── initializers/
│       ├── sendgrid.rb                       # SendGrid SMTP setup
│       └── attr_encrypted.rb                 # Encryption key docs
├── db/
│   └── migrate/
│       ├── 20240101000001_create_reservations.rb        # Initial schema
│       └── 20240101000002_add_encrypted_fields_to_reservations.rb # Encryption
├── bin/                                      # Executables (rails, rake, importmap)
├── public/                                   # Static files (favicon, etc.)
├── vendor/javascript/                        # Vendor JS for importmap
├── docs/                                     # Documentation folder
├── Gemfile                                   # Ruby dependencies
├── package.json                              # Node dependencies
├── README.md                                 # Project overview (Korean)
└── SETUP.md                                  # Detailed setup guide (Korean, Windows-focused)
```

### Key Directory Purposes

- **`/app/controllers/`** - RESTful controllers for HTTP request handling
- **`/app/models/`** - ActiveRecord models with business logic
- **`/app/services/`** - Service objects for external API integrations
- **`/app/jobs/`** - Background jobs for async processing
- **`/app/mailers/`** - Email templates and delivery logic
- **`/config/initializers/`** - Auto-loaded initialization scripts for gems/services
- **`/db/migrate/`** - Database schema migrations

---

## Development Workflows

### Initial Setup

```bash
# 1. Install dependencies
bundle install
npm install

# 2. Configure environment variables
cp .env.example .env  # Create .env and populate with API keys

# 3. Setup database
rails db:create
rails db:migrate

# 4. Build Tailwind CSS
npm run build:css

# 5. Start development server
rails server  # http://localhost:3000
```

### Development Server

```bash
# Primary development server
rails s

# With Sidekiq for background jobs (requires Redis)
# Terminal 1: Redis
redis-server

# Terminal 2: Rails
rails s

# Terminal 3: Sidekiq
bundle exec sidekiq
```

### CSS Development

```bash
# One-time build
npm run build:css

# Watch mode (auto-rebuild on changes)
npm run build:css -- --watch
```

### Database Operations

```bash
# Create new migration
rails generate migration MigrationName

# Run migrations
rails db:migrate

# Rollback last migration
rails db:rollback

# Reset database (DESTRUCTIVE)
rails db:reset

# View schema
cat db/schema.rb
```

### Console & Debugging

```bash
# Rails console
rails console
# or
rails c

# Inside console - useful commands:
Reservation.count
Reservation.last
Reservation.find(1)
ENV['SENDGRID_API_KEY']  # Check env vars
```

---

## Key Conventions & Patterns

### 1. Model Conventions

**Location:** `/app/models/reservation.rb`

#### Validation Rules
```ruby
validates :name, presence: true, length: { maximum: 100 }
validates :phone, presence: true, format: { with: /\A\d{10,11}\z/ }
validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
validates :reservation_datetime, presence: true
validates :coaching_type, presence: true
validates :privacy_agreed, acceptance: true
```

#### Constants
```ruby
COACHING_TYPES = ["출장 코칭", "사무실 코칭", "온라인 코칭"].freeze
SUBJECT_OPTIONS = ["AI 기초 이해", "AI 도구 활용", "콘텐츠 제작",
                   "마케팅 자동화", "수익화 전략"].freeze
```

#### Callbacks
```ruby
after_create_commit :send_notifications  # Triggers email & SMS
```

#### Encryption
```ruby
attr_encrypted :name, key: ENV.fetch('ENCRYPTION_KEY', Rails.application.credentials.secret_key_base[0..31])
attr_encrypted :phone, key: ENV.fetch('ENCRYPTION_KEY', Rails.application.credentials.secret_key_base[0..31])
attr_encrypted :email, key: ENV.fetch('ENCRYPTION_KEY', Rails.application.credentials.secret_key_base[0..31])

# Access is transparent - no special decryption needed:
reservation.name   # Automatically decrypted
reservation.phone  # Automatically decrypted
```

### 2. Controller Conventions

**Location:** `/app/controllers/reservations_controller.rb`

#### RESTful Actions
- `new` - Display empty booking form
- `create` - Process form submission (supports HTML and Turbo Stream)
- `show` - Display confirmation page

#### Strong Parameters
```ruby
def reservation_params
  params.require(:reservation).permit(
    :name, :phone, :email, :reservation_datetime,
    :coaching_type, :requests, :privacy_agreed,
    selected_subjects: []  # Array parameter
  )
end
```

#### Response Formats
```ruby
respond_to do |format|
  format.html { redirect_to reservation_path(@reservation) }
  format.turbo_stream  # Enables async form submission
end
```

### 3. View Conventions

#### Tailwind CSS Styling
- **Mobile-first:** Use base classes + `md:` breakpoint modifiers
- **Utility classes:** Avoid custom CSS - use Tailwind utilities
- **Component structure:** Views are not extracted into partials (monolithic templates)

#### ERB Templates
```erb
<!-- Form helpers -->
<%= form_with model: @reservation, local: false do |f| %>
  <%= f.text_field :name, class: "..." %>
  <%= f.submit "예약하기", class: "..." %>
<% end %>

<!-- Error display -->
<% if @reservation.errors.any? %>
  <div class="text-red-600">
    <%= @reservation.errors.full_messages.join(", ") %>
  </div>
<% end %>
```

### 4. Service Object Pattern

**Location:** `/app/services/sens_sms_service.rb`

#### Usage Pattern
```ruby
class SensSmsService
  # Static class methods
  def self.send_sms(phone, content)
    # External API call logic
  end
end

# Called from jobs or models:
SensSmsService.send_sms(reservation.phone, "예약 확인...")
```

#### Key Responsibilities
- Encapsulate external API interactions
- Handle authentication/signatures
- Format request/response data
- Log errors and results

### 5. Background Job Pattern

**Location:** `/app/jobs/sms_notification_job.rb`

#### Job Structure
```ruby
class SmsNotificationJob < ApplicationJob
  queue_as :default

  def perform(reservation_id)
    reservation = Reservation.find(reservation_id)
    SensSmsService.send_sms(reservation.phone, message_content)
  end
end
```

#### Triggering Jobs
```ruby
# From model callbacks or controllers:
SmsNotificationJob.perform_later(reservation.id)  # Async
SmsNotificationJob.perform_now(reservation.id)    # Sync (testing)
```

### 6. Mailer Conventions

**Location:** `/app/mailers/reservation_mailer.rb`

#### Mailer Methods
```ruby
def confirmation(reservation)
  @reservation = reservation
  mail(to: @reservation.email, subject: "예약 확인")
end
```

#### Async Delivery
```ruby
ReservationMailer.confirmation(reservation).deliver_later  # Recommended
ReservationMailer.confirmation(reservation).deliver_now    # Testing only
```

### 7. Route Conventions

**Location:** `/config/routes.rb`

```ruby
root "home#index"  # Landing page
resources :reservations, only: [:new, :create, :show]  # RESTful subset

# Special routes for dev environment:
get '/_stcore/*path', to: proc { [200, {}, ['']] }  # Health check
get '/favicon.ico', to: proc { [204, {}, []] }       # Favicon handling
```

---

## Security & Privacy

### PII Encryption

#### Encrypted Fields
- `name` → `name_encrypted` + `name_encrypted_iv`
- `phone` → `phone_encrypted` + `phone_encrypted_iv`
- `email` → `email_encrypted` + `email_encrypted_iv`

#### Encryption Key Management
```ruby
# Priority order:
1. ENV['ENCRYPTION_KEY']  # Production (32 characters)
2. Rails.application.credentials.secret_key_base[0..31]  # Fallback
```

#### Best Practices
- **NEVER** log decrypted PII values in production
- **ALWAYS** use ENV['ENCRYPTION_KEY'] in production (not secret_key_base)
- **ROTATE** keys periodically (requires re-encryption migration)

### Authentication & Authorization

#### Current State
- **No authentication** implemented yet (public booking form)
- **Devise gem included** for future admin panel
- **No authorization** - all reservations publicly accessible via ID

#### Future Considerations
- Implement admin authentication with Devise
- Add authorization for viewing reservation details
- Protect admin notification email endpoints

### CSRF Protection
- **Enabled by default** via Rails `protect_from_forgery`
- Form submissions include `authenticity_token`

### SQL Injection Protection
- **ActiveRecord parameterization** prevents SQL injection
- Always use strong parameters in controllers

### XSS Protection
- **ERB auto-escaping** for all `<%= %>` output
- Use `raw` or `html_safe` sparingly and only with trusted content

---

## Testing Strategy

### Current State
**⚠️ NO AUTOMATED TESTS EXIST**

### Recommended Testing Approach

#### Unit Tests (Models)
```ruby
# test/models/reservation_test.rb (not implemented)
class ReservationTest < ActiveSupport::TestCase
  test "should not save without name" do
    reservation = Reservation.new
    assert_not reservation.save
  end

  test "should encrypt personal data" do
    reservation = Reservation.create!(valid_params)
    assert_not_nil reservation.name_encrypted
    assert_equal "홍길동", reservation.name  # Decrypts transparently
  end
end
```

#### Integration Tests (Controllers)
```ruby
# test/controllers/reservations_controller_test.rb (not implemented)
class ReservationsControllerTest < ActionDispatch::IntegrationTest
  test "should create reservation and send notifications" do
    assert_difference('Reservation.count', 1) do
      post reservations_url, params: { reservation: valid_params }
    end
    assert_redirected_to reservation_path(Reservation.last)
  end
end
```

#### System Tests (End-to-End)
```ruby
# test/system/reservations_test.rb (not implemented)
class ReservationsTest < ApplicationSystemTestCase
  test "booking flow" do
    visit root_url
    click_on "예약하기"
    fill_in "이름", with: "홍길동"
    # ...
    click_on "제출"
    assert_text "예약이 완료되었습니다"
  end
end
```

#### Service Tests
```ruby
# test/services/sens_sms_service_test.rb (not implemented)
class SensSmsServiceTest < ActiveSupport::TestCase
  test "should send SMS successfully" do
    VCR.use_cassette("sens_sms") do
      result = SensSmsService.send_sms("01012345678", "Test message")
      assert_not_nil result['requestId']
    end
  end
end
```

### Manual Testing Checklist

When making changes, manually test:

1. **Booking Form Submission**
   - Visit http://localhost:3000
   - Fill out reservation form
   - Verify form validation errors display correctly
   - Submit valid form

2. **Email Notifications**
   - Check logs for ActionMailer delivery
   - Verify SendGrid API call success
   - Inspect email content in SendGrid dashboard

3. **SMS Notifications**
   - Check Sidekiq logs for job processing
   - Verify SENS API call in Rails logs
   - Check Naver Cloud SENS dashboard for delivery status

4. **Database Persistence**
   - Open Rails console: `rails c`
   - Check last reservation: `Reservation.last`
   - Verify encrypted fields exist and decrypt correctly

5. **Encryption Verification**
   - Check `name_encrypted`, `phone_encrypted`, `email_encrypted` are populated
   - Verify `reservation.name` returns decrypted value

---

## Environment Configuration

### Required Environment Variables

Create `.env` file in project root:

```env
# Database
DATABASE_USER=postgres
DATABASE_PASSWORD=your_password
DATABASE_HOST=localhost

# Production Database (use instead of individual vars)
DATABASE_URL=postgresql://user:pass@host:5432/enterai_production

# SendGrid Email
SENDGRID_API_KEY=SG.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
SENDGRID_FROM_EMAIL=noreply@enter.ai
SENDGRID_DOMAIN=enter.ai

# Naver Cloud SENS SMS
SENS_ACCESS_KEY=xxxxxxxxxxxxxxxxxxxxxx
SENS_SECRET_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
SENS_SERVICE_ID=ncp:sms:kr:xxxxxxxxxxxxx:xxxxxxxx
SENS_SENDER_NUMBER=01012345678

# Admin Contact
ADMIN_EMAIL=admin@enter.ai
CONTACT_PHONE=050-0000-0000

# Security
ENCRYPTION_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx  # 32 characters

# Application
HOST=enter.ai  # Production domain
RAILS_ENV=development  # or production
```

### Environment-Specific Configuration

#### Development (`config/environments/development.rb`)
- Auto-reloading enabled
- SMTP configured for SendGrid
- Verbose logging
- Inline queue adapter (sync jobs) - **override with Sidekiq if testing async**

#### Production (`config/environments/production.rb`)
- Code caching enabled
- Eager loading for performance
- **Sidekiq queue adapter** (requires Redis)
- Static file serving conditional on `RAILS_SERVE_STATIC_FILES`

### API Key Acquisition

#### SendGrid
1. Sign up at https://sendgrid.com
2. Navigate to Settings > API Keys
3. Create new API key with "Mail Send" permissions
4. Copy key to `SENDGRID_API_KEY`

#### Naver Cloud SENS (Korean Service)
1. Sign up at https://console.ncloud.com
2. Subscribe to SENS (Simple & Easy Notification Service)
3. Navigate to SENS > SMS
4. Get Access Key & Secret Key from "API 인증키 관리"
5. Create SMS service and get Service ID
6. Register sender number (requires Korean phone verification)
7. Copy values to ENV variables

**Note:** SENS requires Korean phone number for sender registration and only works with Korean phone numbers as recipients.

---

## Common Tasks & Commands

### Database Tasks

```bash
# Create database
rails db:create

# Run migrations
rails db:migrate

# Rollback last migration
rails db:rollback

# Reset database (drop, create, migrate, seed)
rails db:reset

# View database
rails dbconsole

# Generate migration
rails generate migration AddColumnToTable column:type
```

### Asset Management

```bash
# Build Tailwind CSS (one-time)
npm run build:css

# Watch Tailwind changes (continuous)
npm run build:css -- --watch

# Precompile assets for production
rails assets:precompile
```

### Background Jobs

```bash
# Start Sidekiq worker
bundle exec sidekiq

# View Sidekiq web UI (add to routes.rb):
require 'sidekiq/web'
mount Sidekiq::Web => '/sidekiq'

# Clear all jobs
Sidekiq::Queue.new.clear  # From rails console
```

### Console Operations

```bash
# Start Rails console
rails console
# or
rails c

# Production console (read-only recommended)
rails c -e production --sandbox
```

#### Common Console Commands

```ruby
# View latest reservations
Reservation.last(10)

# Find reservation by ID
r = Reservation.find(1)

# Test encryption
r.name_encrypted       # Encrypted value
r.name                 # Decrypted value

# Test email manually
ReservationMailer.confirmation(r).deliver_now

# Test SMS manually
SensSmsService.send_sms("01012345678", "테스트 메시지")

# Test job manually
SmsNotificationJob.perform_now(1)

# Check environment variables
ENV['SENDGRID_API_KEY']
ENV['SENS_ACCESS_KEY']
```

### Debugging

```bash
# View logs
tail -f log/development.log
tail -f log/production.log

# Check Sidekiq logs
tail -f log/sidekiq.log

# View all routes
rails routes

# View specific routes
rails routes | grep reservation
```

### Code Generation

```bash
# Generate model
rails generate model ModelName field:type

# Generate controller
rails generate controller ControllerName action1 action2

# Generate migration
rails generate migration MigrationName

# Generate mailer
rails generate mailer MailerName method1 method2

# Generate job
rails generate job JobName
```

---

## Important Files Reference

### Core Application Files

| File Path | Purpose | Key Information |
|-----------|---------|-----------------|
| `/app/models/reservation.rb` | Core business model | Validations, callbacks, encryption, constants |
| `/app/controllers/reservations_controller.rb` | Booking logic | new/create/show actions, strong params |
| `/app/services/sens_sms_service.rb` | SMS API wrapper | SENS REST API, HMAC signature, phone formatting |
| `/app/jobs/sms_notification_job.rb` | Async SMS job | Background SMS delivery |
| `/app/mailers/reservation_mailer.rb` | Email logic | User confirmation, admin notification |

### Configuration Files

| File Path | Purpose | Critical Settings |
|-----------|---------|-------------------|
| `/config/routes.rb` | URL routing | RESTful routes, root path, health checks |
| `/config/database.yml` | DB connection | PostgreSQL credentials, connection pooling |
| `/config/initializers/sendgrid.rb` | Email SMTP | SendGrid authentication |
| `/config/environments/production.rb` | Prod config | **Sidekiq adapter**, caching, eager loading |
| `/config/tailwind.config.js` | CSS config | Safelist, theme colors, content paths |

### Migration Files

| File Path | Purpose |
|-----------|---------|
| `/db/migrate/20240101000001_create_reservations.rb` | Initial schema |
| `/db/migrate/20240101000002_add_encrypted_fields_to_reservations.rb` | Encryption columns |

### View Templates

| File Path | Purpose |
|-----------|---------|
| `/app/views/layouts/application.html.erb` | Master layout, navigation |
| `/app/views/home/index.html.erb` | Landing page (hero, features, services) |
| `/app/views/reservations/new.html.erb` | Booking form with Tailwind styling |
| `/app/views/reservations/show.html.erb` | Confirmation page |
| `/app/views/reservation_mailer/confirmation.html.erb` | User email template |
| `/app/views/reservation_mailer/admin_notification.html.erb` | Admin email template |

### Documentation

| File Path | Purpose |
|-----------|---------|
| `/README.md` | Project overview, installation, basic usage (Korean) |
| `/SETUP.md` | Detailed setup guide, API key acquisition, troubleshooting (Korean) |
| `/CLAUDE.md` | This file - AI assistant guide |

---

## Gotchas & Known Issues

### 1. Tailwind CSS Not Updating

**Issue:** CSS changes not reflected in browser

**Causes:**
- Tailwind build not run after changing templates
- Browser cache
- Build output not in correct location

**Solutions:**
```bash
# Rebuild Tailwind
npm run build:css

# Check output location
ls -la app/assets/builds/application.css

# Hard refresh browser (Cmd+Shift+R or Ctrl+Shift+F5)
```

### 2. Sidekiq Jobs Not Processing

**Issue:** Background jobs stuck in queue

**Causes:**
- Sidekiq worker not running
- Redis not running
- Environment using inline adapter instead of Sidekiq

**Solutions:**
```bash
# Check Redis
redis-cli ping  # Should return "PONG"

# Start Sidekiq
bundle exec sidekiq

# Verify queue adapter in config/environments/production.rb:
config.active_job.queue_adapter = :sidekiq
```

### 3. Encrypted Data Not Decrypting

**Issue:** `attr_encrypted` returns nil or garbled data

**Causes:**
- `ENCRYPTION_KEY` changed between encrypt/decrypt
- Migration not run for encrypted columns
- Key length not 32 characters

**Solutions:**
```bash
# Check key length
rails c
ENV['ENCRYPTION_KEY'].length  # Must be 32

# Verify encrypted columns exist
Reservation.column_names.grep(/encrypted/)
# Should include: name_encrypted, name_encrypted_iv, phone_encrypted, etc.

# If key changed, data is unrecoverable unless old key available
```

### 4. SendGrid Email Not Sending

**Issue:** Emails not delivered

**Causes:**
- Invalid API key
- FROM email not verified in SendGrid
- SMTP settings not loaded

**Solutions:**
```bash
# Test API key
curl -X POST https://api.sendgrid.com/v3/mail/send \
  -H "Authorization: Bearer $SENDGRID_API_KEY" \
  -H "Content-Type: application/json" \
  -d '...'

# Check initializer loaded
rails c
ActionMailer::Base.smtp_settings
# Should show SendGrid settings

# Verify from email in SendGrid dashboard
# Settings > Sender Authentication
```

### 5. Naver Cloud SENS SMS Failing

**Issue:** SMS not sent, API returns errors

**Causes:**
- Sender number not registered
- Invalid signature
- Phone number format incorrect
- Non-Korean phone number

**Solutions:**
```bash
# Check sender number registration in Naver Cloud console
# SENS > SMS > 발신번호 관리

# Verify phone format (no hyphens/spaces)
phone = "010-1234-5678"
formatted = phone.gsub(/[-\s]/, '')  # "01012345678"

# Check timestamp and signature generation
# Reference: app/services/sens_sms_service.rb

# View logs
tail -f log/development.log | grep "SMS"
```

### 6. Database Connection Errors

**Issue:** `FATAL: database "enterai_development" does not exist`

**Solutions:**
```bash
# Create database
rails db:create

# Check PostgreSQL running
pg_isready

# Verify credentials
cat config/database.yml
```

### 7. Phone Validation Failing

**Issue:** Korean phone numbers rejected by validation

**Cause:** Phone validation expects 10-11 digits without hyphens

**Solution:**
```ruby
# Valid formats:
"01012345678"   # ✓ 11 digits
"0212345678"    # ✓ 10 digits

# Invalid formats:
"010-1234-5678" # ✗ Contains hyphens
"+821012345678" # ✗ Contains country code
"1012345678"    # ✗ Missing leading 0
```

**Frontend should strip hyphens before submission or adjust validation:**
```ruby
# Option 1: Strip in model before validation
before_validation :strip_phone_hyphens

def strip_phone_hyphens
  self.phone = phone&.gsub(/[-\s]/, '')
end

# Option 2: Update validation regex
validates :phone, format: { with: /\A[\d\-\s]{10,13}\z/ }
```

### 8. Turbo Stream Not Working

**Issue:** Form submission reloads page instead of showing Turbo animation

**Causes:**
- `local: false` not set on `form_with`
- Turbo disabled globally
- Missing Turbo JavaScript

**Solutions:**
```erb
<!-- Ensure form uses Turbo -->
<%= form_with model: @reservation, local: false do |f| %>

<!-- Check Turbo loaded in layout -->
<!-- app/views/layouts/application.html.erb should have: -->
<%= javascript_importmap_tags %>
```

---

## AI Assistant Guidelines

### General Principles

1. **Read Before Writing**
   - ALWAYS read existing files before modifying
   - Understand current patterns before suggesting changes
   - Check for similar implementations elsewhere in codebase

2. **Maintain Korean Language**
   - Keep all UI text in Korean
   - Preserve Korean comments
   - Use Korean for user-facing messages

3. **Follow Rails Conventions**
   - Use RESTful routing
   - Follow fat model, skinny controller pattern
   - Place business logic in models, not controllers
   - Use service objects for external API integrations

4. **Security First**
   - Never log decrypted PII in production
   - Always use strong parameters in controllers
   - Validate and sanitize user input
   - Keep encryption keys in ENV variables

### Code Modification Guidelines

#### When Adding Features

```ruby
# ✓ DO: Follow existing patterns
class Reservation < ApplicationRecord
  # Add new validations near existing ones
  validates :new_field, presence: true

  # Add new constants in SCREAMING_SNAKE_CASE
  NEW_OPTIONS = ["옵션1", "옵션2"].freeze
end

# ✗ DON'T: Introduce new patterns without discussion
class Reservation < ApplicationRecord
  include NewComplexModule  # Adds unnecessary complexity
  has_many :some_association  # Adds unplanned features
end
```

#### When Refactoring

```ruby
# ✓ DO: Extract to service objects for external APIs
class NewApiService
  def self.call(params)
    # API interaction logic
  end
end

# ✗ DON'T: Add complex logic to controllers
class ReservationsController < ApplicationController
  def create
    # 50 lines of API integration code  # ✗ WRONG
  end
end
```

#### When Adding Routes

```ruby
# ✓ DO: Use RESTful conventions
resources :new_resource, only: [:index, :show, :create]

# ✗ DON'T: Create custom routes without reason
get '/custom/weird/path', to: 'controller#action'  # Avoid unless necessary
```

### Testing Guidance

**Current State:** No test suite exists

**When adding features:**

1. **Manual test first** - Ensure feature works before committing
2. **Document test steps** - Provide manual testing instructions
3. **Consider test implementation** - Suggest test coverage if adding critical features

**Test suggestions for future:**

```ruby
# Suggest tests like this when adding features:
#
# Recommended test coverage:
# test/models/reservation_test.rb
#   - Validation tests
#   - Encryption tests
#   - Callback tests
#
# test/services/sens_sms_service_test.rb
#   - API integration tests (with VCR)
#   - Error handling tests
```

### Environment Variable Handling

```ruby
# ✓ DO: Use fetch with fallbacks for optional vars
timeout = ENV.fetch('REQUEST_TIMEOUT', 30).to_i

# ✓ DO: Use fetch without fallback for required vars (fails fast)
api_key = ENV.fetch('REQUIRED_API_KEY')

# ✗ DON'T: Use [] for required vars (fails silently)
api_key = ENV['REQUIRED_API_KEY']  # Returns nil if missing
```

### Database Migration Guidelines

```ruby
# ✓ DO: Add indexes for foreign keys and frequently queried columns
add_index :reservations, :email
add_index :reservations, :reservation_datetime

# ✓ DO: Use reversible migrations
def change
  add_column :reservations, :new_field, :string
end

# ✓ DO: Add default values for non-null columns
add_column :reservations, :status, :string, default: 'pending', null: false

# ✗ DON'T: Use execute without down method
def up
  execute "ALTER TABLE..."  # No automatic rollback
end
```

### Common Tasks for AI Assistants

#### Adding a New Field to Reservation

```bash
# 1. Generate migration
rails generate migration AddFieldToReservations field:type

# 2. Edit migration file
class AddFieldToReservations < ActiveRecord::Migration[8.0]
  def change
    add_column :reservations, :field, :type
  end
end

# 3. Run migration
rails db:migrate

# 4. Add to model validation (if needed)
# Edit app/models/reservation.rb
validates :field, presence: true

# 5. Add to strong parameters
# Edit app/controllers/reservations_controller.rb
params.require(:reservation).permit(..., :field)

# 6. Add to form
# Edit app/views/reservations/new.html.erb
<%= f.text_field :field %>

# 7. Test manually
rails s
# Visit http://localhost:3000/reservations/new
```

#### Adding a New Notification Channel

```bash
# 1. Create service object
# app/services/new_notification_service.rb
class NewNotificationService
  def self.send_notification(reservation)
    # Implementation
  end
end

# 2. Create background job
rails generate job NewNotificationJob

# Edit app/jobs/new_notification_job.rb
class NewNotificationJob < ApplicationJob
  def perform(reservation_id)
    reservation = Reservation.find(reservation_id)
    NewNotificationService.send_notification(reservation)
  end
end

# 3. Add to model callback
# Edit app/models/reservation.rb
def send_notifications
  # Existing notifications...
  NewNotificationJob.perform_later(self.id)
end

# 4. Test in console
rails c
NewNotificationJob.perform_now(Reservation.last.id)
```

#### Updating Tailwind Configuration

```javascript
// Edit config/tailwind.config.js

module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js'
  ],
  theme: {
    extend: {
      colors: {
        'custom-blue': '#1DA1F2'  // Add custom color
      }
    }
  }
}
```

```bash
# Rebuild CSS
npm run build:css

# Restart server to see changes
rails s
```

### Code Review Checklist

When reviewing or suggesting code changes:

- [ ] Follows Rails conventions
- [ ] Korean language preserved for user-facing text
- [ ] Validations added for new fields
- [ ] Strong parameters updated in controller
- [ ] Environment variables used for secrets (not hardcoded)
- [ ] PII encrypted if handling personal data
- [ ] Background jobs used for time-consuming operations
- [ ] Error handling implemented with logging
- [ ] Manual testing instructions provided
- [ ] No unnecessary complexity introduced
- [ ] Existing code patterns followed

### Communication Style

**When suggesting changes:**

```markdown
I'll help you add [feature]. Here's what I'll do:

1. [Step 1] - Location: file_path:line_number
2. [Step 2] - Location: file_path:line_number
3. [Step 3]

This follows the existing pattern in [similar_file.rb].
```

**When encountering issues:**

```markdown
I notice [issue] in file_path:line_number.

Possible causes:
1. [Cause 1]
2. [Cause 2]

Recommended solutions:
1. [Solution 1]
2. [Solution 2]

Would you like me to implement [recommended solution]?
```

---

## Additional Resources

### Documentation
- **README.md** - Project overview (Korean)
- **SETUP.md** - Detailed setup guide (Korean)
- [Rails 8.0 Guides](https://guides.rubyonrails.org/)
- [Tailwind CSS Docs](https://tailwindcss.com/docs)
- [Hotwire Turbo Handbook](https://turbo.hotwired.dev/handbook/introduction)

### External Service Documentation
- [SendGrid API Docs](https://docs.sendgrid.com/)
- [Naver Cloud SENS API](https://api.ncloud-docs.com/docs/ai-application-service-sens)
- [attr_encrypted Gem](https://github.com/attr-encrypted/attr_encrypted)
- [Sidekiq Wiki](https://github.com/sidekiq/sidekiq/wiki)

### Korean Tech Stack Resources
- Naver Cloud Platform: https://www.ncloud.com/
- Naver Cloud SENS Setup (Korean): See SETUP.md

---

## Version History

| Date | Version | Changes |
|------|---------|---------|
| 2025-12-08 | 1.0.0 | Initial CLAUDE.md creation |

---

**End of CLAUDE.md**

For questions or clarifications, refer to README.md and SETUP.md for Korean documentation, or consult this guide for AI-specific development workflows.

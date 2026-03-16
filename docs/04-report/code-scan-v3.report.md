# Code Scan v3 - Third-Pass Quality Analysis

## Analysis Target
- Path: `c:\workspace\enterai-main`
- Scope: All source files (models, controllers, views, JS, jobs, mailers, services, routes, schema)
- Date: 2026-03-16
- Context: 19 commits, 10 features in a single session

## Quality Score: 72/100

---

## Issues Found

### CRITICAL (Will break or cause unexpected behavior)

#### C1. `reservation.rb` line 127: `send_review_request` shadows local variable, review never auto-publishes but `create_review!` will crash without required `access_token`

```ruby
def send_review_request
  return if review.present?
  review = create_review!  # <-- shadows the association method `review` with a local variable
  EmailNotificationJob.perform_later(self.id, "review_request")
end
```

**Problem**: On line 126, `review.present?` calls the `has_one :review` association and works correctly. But on line 127, `review = create_review!` creates a **local variable** named `review` that shadows the association. This means if `send_review_request` is called a second time (e.g., if the callback fires again), the guard `review.present?` still reads from the association (which works), so it is not broken per se -- but the real issue is that `create_review!` will be called with **no attributes at all**. The `reviews` table has `access_token NOT NULL`. The `before_create :generate_access_token` callback on Review will handle that. However, `create_review!` passes no `rating`, `content`, or `author_name`, which is intentional (empty shell pattern). **This is actually OK** because all those fields allow nil. The shadow is cosmetic only.

**Revised severity**: LOW. The shadowing is confusing but not a crash.

---

#### C2. `chart_controller.js` line 7: `import("chart.js")` with importmap pinned to a UMD bundle will fail

```javascript
const { Chart, registerables } = await import("chart.js")
```

The importmap pins `chart.js` to `chart.umd.min.js`:
```ruby
pin "chart.js", to: "https://cdn.jsdelivr.net/npm/chart.js@4.4.7/dist/chart.umd.min.js"
```

**Problem**: UMD bundles do not export named ES module exports like `{ Chart, registerables }`. When dynamically imported via `import()`, a UMD module typically exposes its content on the `default` export. The destructuring `{ Chart, registerables }` will yield `undefined` for both, causing `Chart.register(...registerables)` to throw `TypeError: Cannot read properties of undefined`.

**Impact**: The entire admin dashboard charts section will be broken -- no charts render, and a JS error appears in console.

**Fix**: Either:
- Change the pin to the ESM build: `https://cdn.jsdelivr.net/npm/chart.js@4.4.7/dist/chart.esm.js` (but this requires also pinning `@kurkle/color`)
- Or change the import to: `const chartModule = await import("chart.js"); const Chart = chartModule.default || chartModule.Chart;` and call `Chart.register()` without registerables (the UMD bundle auto-registers).

---

#### C3. `reservations_controller.rb` line 78-79: `lookup_results` loads ALL pending/confirmed reservations into memory to filter by decrypted email

```ruby
@reservations = Reservation.where(status: %w[pending confirmed])
                           .select { |r| r.email&.downcase == email && r.phone&.last(4) == phone_last4 }
```

**Problem**: `.select { |r| ... }` is `Enumerable#select`, not `ActiveRecord#select`. This loads **every** pending/confirmed reservation into memory, decrypts all their `email` and `phone` fields, then filters in Ruby. With a growing database, this is an O(n) full-table scan that will:
1. Cause severe performance degradation
2. Potentially cause memory exhaustion in production

**Impact**: Not a crash today with few records, but will become a production outage as data grows. This is an architectural problem inherent to attr_encrypted (cannot query encrypted columns). There is no easy fix without a blind index gem (e.g., `blind_index`).

**Mitigation**: Add a `blind_index` on email so the lookup can be done in SQL, or at minimum add a `LIMIT` and warn users if too many records.

---

#### C4. `admin/reservations/index.html.erb` line 44: Chart data JSON in HTML attribute -- XSS via data values

```erb
data-chart-data-value="<%= { labels: @monthly_trend.keys, ... }.to_json %>"
```

**Problem**: The `<%= %>` tag HTML-escapes the output, which means the JSON `"` characters become `&quot;` inside the `data-*` attribute. When Stimulus reads `this.dataValue`, it parses the attribute value, and the browser has already decoded `&quot;` back to `"`, so the JSON is parsed correctly.

**Revised severity**: NONE. Rails' `<%= %>` escaping + browser attribute decoding handles this correctly. This is standard Rails practice.

---

### HIGH (Will cause failures in specific scenarios)

#### H1. `reviews_controller.rb` line 26: Re-submitting a review overwrites it -- no guard against double-submit

```ruby
def create
  @review = Review.find_by(access_token: params[:review][:access_token])
  # ...
  if @review.update(review_params)
```

**Problem**: The `write` action checks `@review.submitted?` and redirects if already submitted. But `create` has **no such guard**. A user who submits the form, then hits Back and submits again (or uses curl) will overwrite their previous review content. This is a data integrity issue.

**Fix**: Add `if @review.submitted?` guard at the top of `create`:
```ruby
if @review.submitted?
  redirect_to review_path(@review), notice: "..." and return
end
```

---

#### H2. `reservation.rb` line 3: `ENCRYPTION_KEY` fallback in non-production silently uses a 22-character key

```ruby
ENCRYPTION_KEY = ENV.fetch("ENCRYPTION_KEY") { Rails.env.production? ? raise(...) : "dev_fallback_key_0123456789abcdef" }
```

**Problem**: `attr_encrypted` defaults to `aes-256-gcm` which requires a 32-byte key. The fallback key `"dev_fallback_key_0123456789abcdef"` is 34 characters but is used as a string, not hex-decoded. Depending on the `attr_encrypted` version and encoding settings, this may work (key gets truncated/padded internally) or may raise an `OpenSSL::Cipher::CipherError` in development/test. If it works now, changing the key length later will make old data unreadable.

**Impact**: Potential crash in development/test environments. Data encrypted with mismatched key lengths is unrecoverable.

**Fix**: Use exactly 32 bytes: `"dev_fallback_key_01234567890abcde"` (32 chars) or use hex encoding.

---

#### H3. `admin/time_slots_controller.rb` line 38-44: `bulk_create` does not validate `coaching_type` inclusion

```ruby
coaching_type = params[:coaching_type]
```

**Problem**: The `coaching_type` parameter is passed directly to `TimeSlot.bulk_create` which uses `insert_all`. `insert_all` **skips model validations**. An attacker or admin typo could insert time slots with an invalid coaching_type value. These slots would then fail when a reservation tries to use them (because `Reservation` validates `coaching_type` inclusion).

**Fix**: Validate `coaching_type` is in `Reservation::COACHING_TYPES` before calling `bulk_create`.

---

#### H4. `reservations_controller.rb` line 20-21: When a time_slot is selected, `coaching_type` is overwritten from the slot -- but step 5 of the form also sends `coaching_type`

```ruby
@reservation.coaching_type = slot.coaching_type
```

**Problem**: The form has step 5 where the user selects `coaching_type`. If the user selects a time slot in step 4 (which has its own `coaching_type`), and then changes `coaching_type` in step 5, the controller overwrites with the slot's type. This is correct behavior. However, if no time slot is selected (`time_slot_id` is blank), the form relies on the user's step-5 selection AND `reservation_datetime` from the hidden field. But the `reservation_datetime` hidden field in step 4 is set by slot_picker JS. If no slot is selected, `reservation_datetime` will be empty, and the model validation `validates :reservation_datetime, presence: true` will catch it.

**Revised severity**: LOW. The flow is actually consistent. The step-form JS at line 179-184 validates that a slot is selected before proceeding past step 4. If the user bypasses JS (e.g., disables it), the server-side validation catches the missing `reservation_datetime`.

---

#### H5. `_review_card.html.erb` line 4: `review.author_name.first` will crash with `NoMethodError` if `author_name` is nil

```erb
<%= review.author_name.first %>
```

**Problem**: The `HomeController#index` queries `Review.published.submitted.where.not(content: [nil, ""])` but does NOT filter out nil `author_name`. If an admin publishes a review where the user left `author_name` blank, this will raise `NoMethodError: undefined method 'first' for nil`.

**Impact**: The entire home page crashes with a 500 error if any published review has a nil author_name.

**Fix**: Use safe navigation: `review.author_name&.first || "?"` or add `.where.not(author_name: [nil, ""])` to the query.

---

#### H6. `reservation.rb` line 84: `mark_slot_booked` callback runs `after_create_commit` -- race condition with concurrent reservations

```ruby
after_create_commit :mark_slot_booked
```

**Problem**: The `reservations_controller#create` locks the slot with `TimeSlot.lock.find_by(...)` and checks `slot.available?`, but the actual `book!` call happens in an `after_create_commit` callback -- which runs AFTER the transaction commits. Between the commit and the callback execution, another request could also find the slot as "available" and create a second reservation for the same slot.

The lock acquired in the controller is released when the transaction commits, but the slot status is only updated in the after_commit callback (outside the transaction).

**Impact**: Double-booking of the same time slot under concurrent requests.

**Fix**: Move `time_slot.book!` into the transaction itself (e.g., `before_create` or `after_create` instead of `after_create_commit`), or better yet, do `slot.book!` inside the controller's create action within a transaction:
```ruby
ActiveRecord::Base.transaction do
  slot.book!
  @reservation.save!
end
```

---

### MEDIUM (Incorrect behavior but won't crash)

#### M1. `admin/reservations_controller.rb` line 63: Status update allows invalid transitions through admin UI buttons

The `show.html.erb` renders buttons for ALL statuses except the current one:
```erb
<% Reservation::STATUSES.each do |status| %>
  <% if status != @reservation.status %>
    <%= button_to ... %>
```

The controller checks `can_transition_to?`, so invalid transitions are rejected. But the UI shows buttons that will always fail (e.g., "completed" button when status is "pending"). This confuses admins with silent failures.

**Fix**: Only show buttons for valid transitions:
```erb
<% if @reservation.can_transition_to?(status) %>
```

---

#### M2. `admin/reservations_controller.rb` lines 64-68: Duplicate notification dispatch -- status change already triggers `after_update_commit` callbacks

When admin changes status via `update_status`, the controller explicitly calls:
```ruby
SmsNotificationJob.perform_later(@reservation.id, new_status)
EmailNotificationJob.perform_later(@reservation.id, new_status)
KakaoNotificationJob.perform_later(@reservation.id, new_status)
```

But `reservation.rb` also has:
```ruby
after_update_commit :release_slot_on_cancel, if: -> { saved_change_to_status? && status == "cancelled" }
after_update_commit :send_review_request, if: -> { saved_change_to_status? && status == "completed" }
```

The `send_review_request` callback sends an email via `EmailNotificationJob.perform_later(self.id, "review_request")`. So when admin marks "completed":
- Controller sends: SMS(completed) + Email(completed) + Kakao(completed)
- Callback sends: Email(review_request)

This is actually correct -- 4 total notifications (3 status change + 1 review request). No duplicate.

But when admin changes to "cancelled":
- Controller sends: SMS(cancelled) + Email(cancelled) + Kakao(cancelled)
- Callback `release_slot_on_cancel` runs (no notification)

Also correct. **No actual duplicate.** Revised to INFO.

---

#### M3. `step_form_controller.js` line 394: Reference to `currentStepValue === 10` in inline script uses wrong comparison

The inline `<script>` at the bottom of `new.html.erb` tries to call `controllerInstance.updateReview()` when `controllerInstance.currentStepValue === 10`. But step 10 is the "final review" step (0-indexed step 9). The Stimulus value `currentStepValue` is 1-indexed and goes 1-10, so `=== 10` is correct for the final step.

**Revised**: No bug. The check is correct.

---

#### M4. `reservations_controller.rb` line 45: `Date.parse(params[:month])` will raise `Date::Error` if params[:month] is malformed

```ruby
month = params[:month] ? Date.parse(params[:month]) : Date.current
```

**Problem**: No rescue for `Date::Error`. A malformed `?month=invalid` will cause an unhandled 500 error.

**Fix**: Wrap in begin/rescue or use a safe parse:
```ruby
month = begin; Date.parse(params[:month]); rescue; Date.current; end
```

---

#### M5. `home_controller.rb` line 3: `Review.published.submitted` -- no N+1 protection for `reservation` association

```ruby
@reviews = Review.published.submitted.where.not(content: [nil, ""]).order(created_at: :desc).limit(6)
```

The `_review_card.html.erb` calls `review.reservation.package_label` on line 18. Without `.includes(:reservation)`, this triggers 6 separate SQL queries (one per review).

**Fix**: Add `.includes(:reservation)`:
```ruby
@reviews = Review.published.submitted.includes(:reservation).where.not(content: [nil, ""]).order(created_at: :desc).limit(6)
```

---

#### M6. No `Pagy::Backend` included in `ApplicationController` -- public controllers using pagy will crash

The `Admin::BaseController` includes `Pagy::Backend`, but if any public-facing controller tries to use `pagy()`, it would fail. Currently no public controller uses pagy, so this is not an active bug.

**Revised**: INFO only. No current impact.

---

### LOW (Edge cases, minor issues)

#### L1. `time_slot.rb` line 50: `Time.utc(2000, 1, 1, ...)` for slot times -- timezone inconsistency

Time slots store `start_time` and `end_time` as `time` columns (no date component in PostgreSQL). The bulk_create builds them using `Time.utc(2000, 1, 1, ...)`. When Rails reads these back, the time zone handling depends on `ActiveRecord::Base.default_timezone`. If the app uses `:local` timezone, the UTC-stored times will be offset.

**Impact**: Slot display times could be shifted by the server's timezone offset (e.g., KST = +9 hours).

---

#### L2. `reservations_controller.rb` line 20: `.to_datetime.change(...)` may have timezone issues

```ruby
@reservation.reservation_datetime = slot.date.to_datetime.change(hour: slot.start_time.hour, min: slot.start_time.min)
```

`Date#to_datetime` returns midnight in UTC offset +0. Combined with `change()`, the result is a DateTime in +00:00 timezone. But the application likely expects KST (Asia/Seoul, +09:00). This means the stored `reservation_datetime` will be 9 hours behind the intended time.

**Impact**: All reservation datetimes created via slot selection will be stored as UTC, which may display incorrectly unless the app has global timezone configuration.

---

#### L3. `review.rb` line 10: `validates :reservation_id, uniqueness: true` -- no database-level unique constraint

Wait -- checking schema.rb line 69: `t.index ["reservation_id"], name: "index_reviews_on_reservation_id", unique: true`. The DB constraint exists. This is fine.

**Revised**: No issue.

---

#### L4. Routes: `resources :reviews, only: [:create, :show]` -- the `show` action exposes any review by ID without authentication

```ruby
def show
  @review = Review.find(params[:id])
```

Anyone who can guess or enumerate review IDs can view any review (including unpublished ones). Review content may contain personal opinions the user intended to keep private until published.

**Impact**: Information disclosure of unpublished reviews.

**Fix**: Scope to published reviews for public access, or require the access token.

---

## Summary Table

| ID | Severity | File | Issue | Impact |
|----|----------|------|-------|--------|
| C2 | CRITICAL | chart_controller.js | UMD import destructuring returns undefined | Admin charts completely broken |
| C3 | CRITICAL | reservations_controller.rb:78 | Full table scan for encrypted field lookup | Performance bomb as data grows |
| H1 | HIGH | reviews_controller.rb:18 | No double-submit guard on review create | Review data silently overwritten |
| H2 | HIGH | reservation.rb:3 | Encryption key length mismatch risk | Potential crash or data loss |
| H3 | HIGH | admin/time_slots_controller.rb:44 | bulk_create skips coaching_type validation | Invalid slots in database |
| H5 | HIGH | _review_card.html.erb:4 | nil author_name crashes home page | 500 error on home page |
| H6 | HIGH | reservation.rb:84 | Race condition: slot booked after commit | Double-booking possible |
| M1 | MEDIUM | admin/reservations/show.html.erb | Shows invalid transition buttons | Admin confusion |
| M4 | MEDIUM | reservations_controller.rb:45 | Unhandled Date::Error on malformed month | 500 on bad input |
| M5 | MEDIUM | home_controller.rb:3 | N+1 query on review.reservation | 6 extra SQL queries |
| L1 | LOW | time_slot.rb:50 | UTC time storage vs local display | Times off by timezone offset |
| L2 | LOW | reservations_controller.rb:20 | DateTime timezone mismatch | Reservation times stored wrong |
| L4 | LOW | reviews_controller.rb:34 | Public review show exposes unpublished | Info disclosure |

## Priority Fix Order

1. **H5** - Fix `_review_card.html.erb` nil crash (1 line change, prevents 500 on home page)
2. **H6** - Fix race condition in slot booking (move `book!` into transaction)
3. **C2** - Fix chart.js import (change UMD to ESM or fix destructuring)
4. **H1** - Add double-submit guard to `reviews#create`
5. **H3** - Validate coaching_type before bulk_create
6. **M4** - Add rescue for Date::Error in `available_dates`
7. **M5** - Add `.includes(:reservation)` to home controller query
8. **M1** - Only show valid transition buttons in admin
9. **L2/L1** - Audit timezone handling across the app
10. **C3** - Plan blind_index migration for encrypted field lookup (larger effort)

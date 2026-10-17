## Shared page reads for customers and providers — 2026-10-17

User action: Open Notifications, switch filters, refresh or load an older page.
Both authenticated roles use the existing shared screen/controller and mark only
the displayed page's unread IDs as read, up to 20. The page-read hint and explicit
Retry behavior are shared; neither inbox offers a whole-history Mark all action.
Unfetched history and arrivals after the fetch stay unread. Read rows stay visible,
including in Unread, and pagination retains its cursor. Hidden/background pages
wait until visible. Empty/already-read pages do not issue a read request.

API: Existing owner-scoped PATCH /notifications/read-page with
{"ids":["<UUID>"]}; response data {"ids":["<UUID>"],"unread_count":3}.
No backend change, new endpoint, analytics event, polling or background GET.
Role-specific typed destinations and localized Arabic/English content are retained.
Tests cover both roles, bounded batches, pagination, failed reads/retry, session
replacement, background visibility, navigation and narrow/large-text layouts.
This supersedes the historical customer explicit row/mark-all behavior below.

Verification: all 492 Flutter tests passed, including 100 focused notification
and shell tests. Flutter analysis and custom lint reported no issues. Customer
English/Arabic previews were inspected; both roles also passed narrow layouts
and 200% text tests. Existing backend behavior was reused without API changes.

## Provider notifications — implementation contract (2026-10-17)

Providers open Notifications from the dashboard bell or More. The shared inbox
keeps its 20-item cursor pages. Once a provider page is displayed, Flutter sends
one explicit `PATCH /notifications/read-page` with `{"ids":["<notification UUID>"]}`
for that page's unread rows. The authenticated owner-only response is
`{"success":true,"data":{"ids":["<notification UUID>"],"unread_count":3}}`.
IDs must be distinct UUIDs (1–20); a missing or foreign ID rejects the entire
batch. Replays preserve read timestamps. GET stays read-only. Later pages, unseen
history and arrivals after the fetch are not marked read. Read failure retains
unread state and offers explicit retry. Rows remain visible after acknowledgement,
including in Unread. Customers now use the same page-read behavior (see above).

Reuse the notification data/domain/controller and Android delivery infrastructure
for both roles. New accepted-offer and store-review database alerts are written
inside their existing transactions; push dispatch remains after commit. Existing
payment, completion, direct-request and incoming-message alerts are reused.
No new schema/backfill or historical pushes. General-order inbox alerts remain;
only direct new orders trigger push. Push payloads contain allowlisted IDs and
generic localized text, never message content, prices or review reasons.

Typed role-specific navigation opens offers, general/direct/paid orders, chats or
store-request status. Unknown targets remain readable without arbitrary links.
Loading/empty/offline/pagination/read retry and session replacement are covered.
Arabic/English, RTL, narrow layouts and large text use existing shared components.
No polling or background inbox/count fetching; permission and token sync reuse
the existing Android flow. iOS, inventory and unrelated settings remain deferred.
Tests cover bounded reads, ownership/morph isolation, arrivals/cursors, transaction
rollback/replay, provider push privacy/role/session guards, navigation, pagination,
failed receipts and logout. Run API suites, Flutter tests and analysis; live FCM
delivery requires configured server credentials and a running push worker.


Verification on 2026-10-17: all 482 Flutter tests passed; full Flutter analysis
and custom lint reported no issues. All 73 focused Flutter notification/shell tests
passed, including provider and customer push navigation, bounded acknowledgements,
pagination, failed reads, hidden/background screens and same-user session changes.
Arabic/English previews were inspected and layouts passed at 320 dp / 200% text.

The API focused run passed 61 tests (497 assertions). The complete backend suite
finished with 537 passing tests and four pre-existing failures (4,255 assertions).
The baseline before changes was 529 passing tests with those same four failures:
`AuthRateLimitTest`'s two OTP IP/mobile throttling cases, and
`GeneralOrderDetailsTest`'s paid-field and demo-seed-count expectations. Notification
tests use isolated SQLite data and fake HTTP delivery. PHP formatting and diff
checks passed. No migration, seed reset, real store decision, payment, customer
message or live push was performed for verification.

Runtime check on 2026-10-17: local Firebase delivery is enabled and a credential
path is configured; no credential values were printed or changed. The Laravel API
is running, but no `queue:work` process was running at verification. Start the
existing push worker to deliver queued phone alerts:

```powershell
php artisan queue:work database --queue=push --tries=4 --timeout=40
```

No live push, customer message, payment or store-review action was sent as a test.
Older customer-only implementation notes below are historical; this provider
contract supersedes their role restriction, while preserving the customer flow.


# Android customer push update — 2026-10-08

The customer app includes FCM registration, token rotation, locale updates,
permission handling, logout cleanup and validated notification-tap navigation.
Android displays background alerts; foreground messages show localized banners.
Server credentials and a queue worker are required to enable real delivery.

**The 30-second polling mechanism has been removed.** Notification lists load
when the inbox opens or the user explicitly refreshes, changes filter or loads
another page. Home, More, elapsed time, app resume and incoming pushes do not
fetch notification lists or unread counts. Read actions update state locally.
The badge uses the most recent loaded count plus locally received pushes; it
resynchronizes on inbox entry/refresh and starts at zero before that session has
data. No polling timer replaces the removed timer.

Signup sends only account details and no longer reads an FCM token. The
push feature registers it after authentication; Laravel stores it exclusively in
`device_tokens`, linked to the account and the current login session. The legacy
`users.device_token` field and the signup-only token reader have been removed.

Device registration uses POST /api/push/device; removal uses DELETE on the same
route. These lifecycle requests are independent of inbox reads. An unchanged
successful registration does not issue repeat requests on resume. The inbox has
an Android notification-settings button. Logout attempts to unregister the
device, clear displayed alerts, disable FCM auto-init, invalidate the installation
token and revoke the Laravel session before clearing local storage.

Deploy the Laravel migrations and Composer dependency before this Flutter build.
See [backend setup](../OctoGear-api/PUSH_NOTIFICATIONS.md) for credentials, queue
commands, test coverage and offline limitations. Sending is disabled until those
credentials are configured. Only existing customer offer/message events are sent;
this does not introduce customer order-status events or change iOS/payment work.

The historical section below describes the original inbox implementation; its
polling/deferred-FCM statements are superseded by this update.

Verification: all 320 tests in the full Flutter regression run passed. Final
notification tests also verify explicit refresh, no fetch on badge changes or
resume, session-safe token rotation, logout and actual foreground-banner
navigation. Flutter analysis, custom lint and the Android debug build passed.
The Laravel push/inbox/chat/logout checks passed 48 tests (265 assertions).
Live Firebase delivery has not been verified because server credentials are not
configured; code tests use fake messaging and HTTP.

# Customer notification inbox — 2026-10-06

The customer Home header has a notification bell with an unread badge. More has
the same inbox entry and badge. The typed route is `/customer/notifications`.
Opening the inbox is read-only; tapping a notification marks it read, then opens
its offer, conversation or order. A failed read request shows feedback but still
allows the destination to open. Mark all as read and the All/Unread filters are
available without navigating away. Labels are localized in English and Arabic;
the app does not reuse the language of server-generated notification messages.

## API and deployment

Deploy the accompanying Laravel changes before shipping this Flutter build.
These additive endpoints use the existing Sanctum authentication, active-user
middleware and notification table; no new migration or dependency is required:

- `GET /api/notifications/inbox?unread=0|1&cursor=...` returns
  `data: {items: [...], unread_count: integer, next_cursor: string|null}`.
  Each item uses the existing NotificationResource (`id`, `payload`, `is_read`,
  `created_at`, and existing metadata). Pages contain up to 20 rows, ordered by
  descending created_at and UUID. Cursor pagination remains stable when new
  rows arrive or older rows are marked read in the Unread view.
- `GET /api/notifications/unread-count` returns `data: {unread_count: integer}`.
- Existing `PATCH /api/notifications/{uuid}/read` and
  `PATCH /api/notifications/read-all` are reused. Writes are idempotent and
  scoped to the authenticated account. The notification policy checks both
  the notifiable model type and account ID.

The original paginated `GET /api/notifications` contract remains available for
existing clients. No notification content or token appears in a URL. Invalid
cursors return validation errors, and supplied cursors cannot change ownership.

## Delivery and supported events

Existing `new_offer` and provider `new_message` events already create database
notifications for customers. Offer links carry the exact order and offer IDs;
message links carry the conversation ID. Order-shaped stored payloads are also
handled, but the current backend's payment/completion listeners notify providers,
not customers. This slice does not invent customer order-status events.

This is **in-app delivery**, not background push. The customer shell fetches the
unread count on entry and every 30 seconds while foregrounded. Polling pauses
after failures and while backgrounded; app resume and manual refresh retry. The
Home pull-to-refresh also refreshes the badge. A changed count refreshes the
visible inbox's first page; older loaded history is retained until manual refresh.
FCM background delivery, permission prompts and device-token registration remain
a separate integration. Reading a chat and reading an inbox notification remain
independent actions; this badge is unread notifications, not unread messages.

## Reliability and validation

The repository validates UUIDs, dates, counts and read receipts. Known payloads
require positive numeric target IDs. Unsupported payloads remain readable as a
generic update and cannot navigate to arbitrary URLs. Destination screens enforce
their existing missing-resource and permission states. No attachment download or
external navigation is triggered by a notification.

Read operations are serialized, duplicate taps cannot push duplicate pages, and
late responses cannot repopulate a signed-out account. Failed pagination preserves
rows and cursor for retry; merging pages removes duplicates. Failed writes keep
the existing unread state and allow explicit retry. Read actions do not require
notification permission.

Tests cover API contracts, event-to-inbox delivery, account isolation, cursor
validation, insertion/read pagination, failed receipts, logout during a read,
double taps, foreground lifecycle, filters, empty/error states, typed navigation
and English/Arabic at 200% text size. Rendered preview fixtures are saved under
ignored `build/notification-preview-en.png` and `build/notification-preview-ar.png`.

Verification: the full Flutter regression suite passed 285 tests. The final
notification/shell run passed 37 tests, including an additional regression that
keeps older unread history reachable after every visible row is marked read.
Flutter analysis and custom lint passed. Laravel's notification/shared-feature
suite passed 28 tests (140 assertions), and Pint passed for the changed PHP files.
The Android x64 development debug APK built successfully. The pre-existing Kotlin
plugin migration warning remains; this slice adds no dependency or Gradle changes.

Android verification: the debug app was built, installed and launched on emulator-5554 on 2026-10-17. Flutter reported app.started, then detached successfully; the app process remained running. This confirms startup, not live FCM delivery.

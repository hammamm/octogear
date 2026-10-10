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

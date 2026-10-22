# Customer service chat (2026-10-21)

Approved first version: a single text-only support conversation for each account,
shared across customer/provider role changes. The backend enforces the unique
account identity. Support is separate from customer/provider marketplace chats.

## Entry and lifecycle

- Authenticated headers use the shared headset button; More includes the same
  support destination and unread badge. Authentication screens do not offer support.
- Language selection remains on authentication/account registration and in More
  and its settings page. Both supported locales and RTL remain available.
- An account with no conversation sees a welcome and Start chat action. Neither
  action inserts a record. The first successful text send atomically creates the
  conversation and its first message.
- Messages contain plain text, up to 2,000 characters. An uncertain send retains
  its UUID and exact text for manual retry. No automatic write retries.
- Closed history remains readable. The composer is replaced with a resolved
  notice and explicit Reopen action, which reuses the same conversation.
- The backend records status transitions and rejects stale versioned changes.

## Unread and session behavior

The application scope loads the summary after authentication/session restoration.
The headset and More entry display the server unread count; zero is hidden and
counts above 99 are abbreviated. Closed unread replies still count.

Support events reuse the existing private Sanctum-session WebSocket connection:
`support.updated` carries a versioned conversation and optional message. Snapshots
cannot replace a newer version. Messages merge by ID; live events do not advance
the HTTP reconnect cursor. HTTP catches up after reconnect/entry. There is no timer
polling. A support FCM event can refresh this summary when the socket is unavailable;
this is separate from the existing notification inbox count contract.

The visible, foreground conversation acknowledges incoming messages through a
known message ID after a short debounce, only while viewing its newest messages.
Failed read acknowledgements retain the badge and expose Retry. Outgoing messages
are not counted as unread. Logout/session replacement clears state and discards
late responses; all support writes carry the originating access-token guard.

Android push uses generic localized text and IDs, never message content. Its tap
opens the role-specific support route under the existing central route guard.
The server skips delivery of a reply already acknowledged in the support chat.

## API and architecture

Source of truth: `../OctoGear-api/SUPPORT_CHAT.md` and its tested endpoints.
User routes are `GET support/conversation`, `GET support/conversation/timeline`,
`POST support/conversation/messages`, `PATCH support/conversation/read`, and
`PATCH support/conversation/reopen`. No conversation ID is accepted from Flutter
to select another account's support conversation.

The feature follows the existing domain repository/use-case, remote data source,
typed DTO and Riverpod controller boundaries. It reuses the common API client,
chat transport, message bubble/day labels, connection indicator and More entries.
Routes use generated typed helpers. The web dashboard is intentionally deferred;
administrator listing, filtering, reply, read, status, audit and socket APIs exist
in Laravel for that next phase.

## Verification and rollout

Run `flutter analyze`, `dart run custom_lint` and `flutter test`. Focused tests cover
first send/empty preview, retries, session isolation, snapshot races, HTTP catch-up,
closed/reopen history, numeric badges, read debounce, both locales at 320dp and
200% text, HTTP payload/session guards and the shared real local WebSocket.

Deploy the backend and additive support migration before this Flutter build.
Use the existing supervised realtime and push workers; restart them for the new
job types. No web UI change or real user message is needed for verification.

Verification on 2026-10-21: the full Flutter suite passed all 567 tests, including
20 support-specific tests and the existing real local WebSocket test extended for
support events. Both customer/provider shell tests cover the new header spacing
and More layout. Actual device push delivery and the future web dashboard were
not exercised by these automated checks.
Final static checks: flutter analyze and dart run custom_lint both completed with no issues. Diff whitespace checks passed.

## Bottom-aligned support conversation — 2026-10-22

Customer and provider support use the same screen. Keep the composer and closed
conversation action at the bottom, with the reversed timeline filling the remaining
height. Cap the action area's height to preserve scrolling with the keyboard and
large Arabic/English text. API, navigation, message ordering, read acknowledgements,
and notification behavior are unchanged. Verify the existing support widget tests,
including composer position, and run targeted analysis.

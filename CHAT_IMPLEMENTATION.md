# Offer chat — 2026-10-04

User action: Open Chat from an offer without writing anything. Read an existing
offer conversation or compose the first text; the first send atomically creates
the conversation and message. Reopening the same offer reuses that conversation.

Roles/permissions: Only the order customer can start its offer chat. Laravel
resolves the provider from offer.store.user_id, never a client-supplied recipient.
Only participants can read/send/mark read. New sends require active participants
and, for offer chats, an available active store. Existing history remains readable.
The header exposes store.name and store.employee_name only in authorized chat.

API: GET customer/orders/{order}/offers/{offer}/conversation returns
{conversation: null|{id,...}, can_send: true|false, store: {id,name,employee_name}, order_id, offer_id}.
POST the same path plus /messages accepts {content,client_message_id: UUID} and
returns {conversation: {...}, message: {id,content,is_mine,is_read,created_at,
client_message_id}}. Conversation and first message commit together. An additive
migration gives conversations a nullable unique offer_id; legacy chats are kept
without guessed offer links. Messages gain nullable client_message_id with a
sender/key uniqueness constraint and TEXT content for the existing 2000 limit.
GET conversations/{id} returns authorized metadata; GET .../timeline accepts
before_id or after_id and returns {messages: [... newest first],has_more: bool}.
POST .../messages accepts the same idempotent message payload; PATCH .../read
accepts through_id and marks only incoming messages up to that visible message.
GET conversations?with_messages=true remains paginated and sorts by latest message ID, including ties within the same second. Existing legacy API callers keep their empty-conversation listing behavior.

State: Explicit loading, empty and retry states; failed sends retain the exact
content and UUID for manual retry. No automatic write retry. Drafts live only in
memory and are cleared on disposal/session change. Bounded polling runs only at the newest messages on
the visible resumed route; errors stop polling until explicit retry. Older-page
errors retain history. Incoming messages do not jump the reader away from older
history. Read updates apply only when the user is at the newest messages.

Navigation: Typed customer offer-chat and conversation routes; a minimal provider
Chats entry allows the other participant to reply using the same shared feature.
This does not build provider orders, inventory or onboarding.

Locale/RTL: Arabic/English, directional layout, colored outgoing and neutral
incoming bubbles, selectable text, a localized time on every message and local
calendar-day separators (Today, Yesterday, weekday within seven days, date beyond).
Store employee name is shown below the store name with a circular store avatar.
No fabricated online/typing status, phone controls, calls, images or attachments.

Notifications: Keep the existing backend database message notification once per
new message. No push/Firebase changes. Unread counts come from Laravel.

Tests: Atomic first send, no write on opening, offer ownership/nesting, participant
authorization, whitespace/length, idempotent replay/conflict, pagination, read
boundaries, headers, DTOs, retry, dates, colors, RTL, large text and navigation.


Verification: the full Flutter suite passed 247 tests. After the final keyboard
and synchronization-race fixes, all 15 chat tests passed, including seven rendered
UI/keyboard checks. English/Arabic font-rendered previews are in ignored
build/chat-en.png and build/chat-ar.png. The cursor is advanced by fetched history,
not by send receipts, so simultaneous incoming messages cannot be skipped or marked
read before they are fetched. Loading history preserves failed-send retry state.

Laravel: all 28 focused chat/shared-feature tests passed (109 assertions), and Pint
passed. Full backend regression: 399 passed, three pre-existing expectation
mismatches remain (two AuthRateLimitTest cases expect three attempts although the
configured limit is six; GeneralOrderDetailsTest expects 30 seeded requests while
the seeder creates 50). Authentication and seed behavior were not changed.

Final Flutter analysis reports no issues. The Android x64 debug APK builds with
the existing Firebase Kotlin Gradle compatibility warning.

The final verified Android x64 debug APK was installed on emulator-5554. Local
API health returned HTTP 200, and adb reverse maps device port 8000 to Laravel.
Screenshots are rendered test fixtures; no real customer offer/message was changed
by validation. Full interactive two-account device testing remains a manual check.

# Quiet chat offer lookup — 2026-10-20

User action: Opening a provider conversation silently checks for editable offers.
Loading and successful empty results occupy no space: no spinner, placeholder,
empty message or refresh button. A nonempty result reveals the existing single
offer action or multiple-offer chooser. Lookup errors retain explicit Retry;
an already opened chooser retains its pagination/loading/error feedback.
The existing provider authorization, endpoint, editor route, session isolation,
chat disposal, messages and drafts are unchanged. No new strings or side effects.
Verification: update the existing widget checks for hidden loading/empty states,
zero reserved height, appearance after loading, and disappearance after refresh;
retain single/multiple-offer, error/retry and Arabic/English coverage.

Verified: all 79 affected chat, offer and provider-shell tests passed; Flutter
analysis and custom lint reported no issues. No device build or live API changes.

# Provider offer editing from chat — 2026-10-19

Existing provider conversations expose editable offers for that customer through
the authorized `GET /provider/conversations/{conversation}/offers` endpoint.
A sole offer opens the existing price/notes/photos editor; multiple offers use a
paginated chooser with request, offer, store and total, marking the current chat's
offer. The typed editor stays under Chats and returns without losing the draft.
Accepted/paid orders and customer request fields retain their existing rules.
No automatic message or offer write occurs on opening. See the current contract
and verification in [PROJECT_DOCUMENTATION.md](PROJECT_DOCUMENTATION.md#edit-provider-offers-from-chat--2026-10-19).
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

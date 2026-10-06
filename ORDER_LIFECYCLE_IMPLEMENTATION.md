# Customer order lifecycle — 2026-10-06

The approved launch flow is online payment and store pickup. The order panel has
two local preview options: Pickup (selected by default) shows store details and
the existing checkout; Delivery shows Coming soon and hides checkout. Selecting
either option does not write to the API or change the order's fulfillment method.
No delivery checkout or shipping fee is enabled. The selector supports Arabic,
English and large text, with eight existing screen tests and clean analysis.
The payment gateway has not been chosen. The user explicitly requested preparing
checkout first: Pay online is disabled and Flutter does not call the stub payment
endpoint or collect card details.

## Customer flow

- Selected offers have a Track order action opening their owning order details.
- Home's offer carousel now places accepted offers awaiting payment before
  available offers, before applying its eight-card preview limit. These reminders
  show an Accepted / Awaiting payment badge and open the owning order's payment
  details. A newly prioritized accepted offer resets the carousel to the start.
  Paid/completed/cancelled orders do not appear as payment reminders. This reuses
  the existing loaded order pages; the carousel is still a recent-order preview.
  The Home follow-up passes five focused tests (including phone-width scroll
  reset and Arabic/English large-text layouts), clean Flutter analysis and an
  Android x64 debug build.
- Order details show status guidance and progress through offer selection,
  confirmed payment and confirmed receipt. These are status milestones, not
  invented shipment events or timestamps.
- Pickup details include the selected store, employee name, a copy-location
  action when a store URL exists, and the exact offer-specific chat route.
- Awaiting-payment orders show the offer total in SAR using integer minor units.
- Server-confirmed paid orders offer I received my parts with an explicit
  confirmation to collect and inspect the parts first.
- Cancellation is a distinct action from deleting a request. It requires
  confirmation, closes an eligible unpaid order, and retains order history.
- Completed, rejected and cancelled orders show appropriate final-state guidance.
  Payment details expose the payment reference, amount, status, method and record
  date. This is payment history, not a generated tax invoice.

## Contracts and safeguards

Customer order resources add `can_cancel`, `can_confirm_received`, and nullable
`payment_summary`. Store summaries include `employee_name` and `url_location`.
Old responses without action flags fail closed in Flutter. Payment summaries
must match the owning order. No database migration is required for this slice.

The feature repository uses authenticated POST `/customer/orders/{id}/cancel`
and `/customer/orders/{id}/received`. It validates the returned ID and terminal
status. The controller reloads the order before a write, checks eligibility and
selected offer, blocks duplicate taps, and invalidates detail and shared
Orders/Home caches after success. An uncertain response requires a read before
another explicit action; no writes are automatically retried. Pull-to-refresh
also reconciles this state. Edit/delete and lifecycle controls disable while the
other action is unresolved. Arabic, English, RTL and large text are supported.

Laravel locks and reloads the order for receipt confirmation and cancellation.
Repeat terminal requests are idempotent; completion dispatches its event only
once, after commit. Any retained payment attempt (including soft-deleted records)
prevents cancellation pending reconciliation. Payment initialization uses the
same order lock so stale order objects cannot start charging a cancelled order.
Existing authorization and cancellation offer cleanup remain in place.

## Validation and remaining work

Six new backend tests plus related payment, cancellation, history and admin tests
pass: 41 tests, 219 assertions. Thirteen new Flutter contract/controller/widget
tests cover permissions, authentication, stale state, duplicate taps, uncertain
responses, confirmation/cancellation, selected-store navigation, disabled payment
and Arabic/English layouts at 200% text size. Rendered fixtures are in ignored
`build/order-flow-en.png` and `build/order-flow-ar.png`.

The full Flutter regression suite passes all 263 tests, Flutter analysis and custom lint are clean,
and targeted backend Pint checks pass. The Android x64 debug APK builds
successfully. The pre-existing Firebase Kotlin Gradle compatibility warning
remains unchanged. The APK was installed on emulator-5554 and its MainActivity
was confirmed running. This launch smoke check did not modify real orders.

Before online checkout launches, choose and implement a gateway with tokenized or
hosted collection, server-confirmed payment state, webhook verification,
idempotency and reconciliation. The existing Laravel stub is not a real payment
integration. Pickup readiness and scheduling currently happen through store chat;
there is no claim of live delivery or pickup-readiness tracking. Real payment and
two-account physical-device acceptance testing remain outstanding.

# OctoGear Flutter: required engineering instructions

These instructions apply to the Flutter app at `C:/Tamkkun/OctoGearProject/octogear`, including implementation questions, reviews, fixes and refactors. Follow them for every project-related request, including when the chat starts outside this repository.

## Required documentation for every request

Before recommending code changes or editing files:

1. Confirm the target repository and read applicable `AGENTS.md` / `AGENTS.override.md` files.
2. Read [README.md](README.md) and [PROJECT_DOCUMENTATION.md](PROJECT_DOCUMENTATION.md). Read the complete relevant sections, including the architecture, source-of-truth order, localization, routing, API/session, testing and AI-assisted change rules, plus the current contracts for the affected feature. Do not rely solely on memory from a previous request.
3. Read the additional feature documents below when their subject is involved. Follow their relevant linked documentation, including confirmed backend contracts when needed.
4. Briefly identify the guidance used and the bounded change before substantive implementation. If a required document cannot be read, state the limitation. Retrieve missing portions when output is truncated; filenames or headings alone do not count as reading.

| Document | When to read |
| --- | --- |
| [README.md](README.md) | Every request: project entry point, environments, local setup and verification. |
| [PROJECT_DOCUMENTATION.md](PROJECT_DOCUMENTATION.md) | Every request: development contract, architecture, engineering rules and relevant feature decisions. |
| [SUPPORT_CHAT_IMPLEMENTATION.md](SUPPORT_CHAT_IMPLEMENTATION.md) | Support conversations, unread badges, close/reopen, administrator support APIs and realtime delivery. |
| [CHAT_IMPLEMENTATION.md](CHAT_IMPLEMENTATION.md) | Conversations, message sending/retry, history, read state or chat navigation; also read the newer chat updates in PROJECT_DOCUMENTATION.md. |
| [NOTIFICATIONS_IMPLEMENTATION.md](NOTIFICATIONS_IMPLEMENTATION.md) | Customer/provider inbox, page reads, badges, Android push, token/session lifecycle or notification navigation. |
| [ORDER_LIFECYCLE_IMPLEMENTATION.md](ORDER_LIFECYCLE_IMPLEMENTATION.md) | Order status, cancellation, receipt confirmation, pickup, checkout or payment history. |

This file is an instruction map, not a replacement for the source documents or their detailed API examples and verification requirements. Keep the map current when documentation changes.

## Resolve current and historical guidance

- Follow the development contract's source-of-truth order: explicit owner decisions, confirmed Laravel behavior and validated payloads, the development contract, brand guidance, then wireframes.
- Read newer dated feature updates before applying older implementation notes. Confirm relevant behavior against current code and tests; surface genuinely unresolved conflicts instead of silently changing a business rule.
- Chat WebSocket and navigation updates supersede historical polling and placeholder descriptions. Current notification updates supersede polling, signup-only FCM capture, customer-only delivery and whole-history read controls.
- Use the README and current environment section for development/staging/production configuration; do not apply a conflicting historical environment rule without checking its replacement.
- Historical test counts, runtime checks, tunnel URLs and deployment notes are evidence from that date, not proof of current state. Documented commands and earlier deployment/reset approvals do not authorize running them now.

## Reuse and preserve behavior

- Search existing widgets, controllers, use cases, repositories, data sources, models, providers and utilities before adding another implementation. Reuse existing shared components and business rules.
- Extract meaningful repeated same-class logic into a clearly named private helper when it improves clarity. Preserve differences in authorization, state, payloads and side effects; avoid wrappers around trivial statements or speculative abstractions.
- Unless a change is requested, preserve public contracts, API endpoints and payloads, null/omitted/empty semantics, validation, permissions, ordering, pagination, navigation, localization, retry behavior, caches, session isolation and side effects.
- Preserve unrelated and concurrent user edits. Review changed call sites and the final diff; avoid unrelated cleanup.

## Flutter architecture and UI boundaries

- Use Riverpod for dependency injection and state management. Preserve `presentation -> domain` and `data -> domain + core`; do not reintroduce GetIt or parallel service locators.
- API features use domain repository contracts and use cases. Controllers invoke use cases; provider factories assemble implementations. Only remote data sources depend on the HTTP client. JSON DTOs stay in data; raw maps and dynamic transport values must not escape that layer.
- Keep request/state/navigation/business logic out of generic UI primitives. Reuse the existing OctoGear design system and feature boundaries. Static presentation screens need no artificial repository/use-case layers.
- Use the central GoRouter, semantic paths and generated typed route helpers. Keep global role/session redirects in the central guard. Regenerate affected generated code; never hand-edit generated files.
- Use the approved OctoGear assets, theme and Noto Sans Arabic. Do not recreate or alter the official logo from screenshots or wireframes.
- Put visible text in both Arabic and English translation files and translate through the current BuildContext. Preserve RTL/LTR, directional layout, large text, accessibility, keyboard-safe forms and readable LTR phone/OTP values.
- Preserve the shared API locale interceptor and locale-dependent cache invalidation. Do not translate backend-localized content again in Flutter.

## API, session and feature safeguards

- Use existing configuration, API client, typed envelopes and failure handling. Confirm endpoints and response examples before implementing a flow; do not invent backend capabilities.
- Keep credentials in secure storage and sensitive authentication hand-offs in memory. Do not expose tokens, OTPs, personal data or secrets in logs, routes or navigation arguments. Preserve existing session validation and logout cleanup.
- Keep loading, empty, validation, offline, error and retry states explicit. Do not call APIs from widget build methods. Preserve in-flight guards, mounted/lifetime checks and protection against stale responses after account/session changes.
- Preserve feature-specific write idempotency, manual retry and uncertain-result reconciliation. Do not add automatic write retries or duplicate actions merely to hide errors.
- Preserve the current shared chat transport, reconnect recovery and message deduplication; do not restore chat or notification polling. Read the full current feature contract before changing read acknowledgements or background behavior.
- Preserve the documented pickup/checkout boundary: the payment stub is not a live gateway. Do not enable charging or invent delivery/status transitions as cleanup. Respect deferred iOS work and current environment/signing requirements.

## Repository ownership

- Flutter and Laravel are separate projects. Keep Flutter work and commits in this repository; never copy backend source or history into it.
- For any Laravel work, first read `C:/Tamkkun/OctoGearProject/OctoGear-api/AGENTS.md` and the documentation it requires. Flutter instructions do not replace backend guidance, and Laravel architecture rules do not apply to Flutter.
- Follow the existing AI-assisted change protocol for product/API decisions and backend changes. Existing explicit authorization applies; do not reopen settled decisions simply because an older document lists them as unresolved.

## Verification and completion

- Inspect existing tests/configuration and run checks appropriate to the change. Material Flutter foundation or feature changes require `flutter analyze` and `flutter test`; run `dart run custom_lint` and feature-specific architecture, contract, controller, widget or integration checks where required by the development contract.
- Preserve coverage for localization, role/session changes, request races, retries and affected UI states. Do not weaken assertions or change behavior to hide a pre-existing failure.
- For documentation-only changes, verify referenced paths, instruction consistency and the final diff; no application build is necessary solely for prose edits.
- Add the required feature implementation note before feature coding and update affected documentation when contracts, routes, environment behavior, ownership or feature decisions change.
- Report what changed, actual check results, pre-existing failures and unverified/manual steps. Do not claim a passing suite, live backend/device verification or release readiness without evidence.

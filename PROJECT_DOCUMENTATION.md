# OctoGear - Mobile Application Development Contract

## Purpose

OctoGear is a production mobile marketplace for automotive spare parts. It serves people who need parts and store owners/providers who publish inventory and respond to requests. The mobile application must support Android and iOS, Arabic and English, right-to-left and left-to-right layouts, secure authentication, observable production behavior, and maintainable future changes.

This document is the source of truth for developers and AI assistants working in the Flutter repository. It replaces the old Sahala scaffold description. The old implementation is temporary migration material only; it is not the architecture or visual identity for OctoGear.

## Source-of-truth order

When sources disagree, use this order:

1. Explicit approved product decision from the project owner.
2. Confirmed Laravel API behavior and validated request/response example.
3. This development contract.
4. OctoGear brand guideline PDF.
5. Wireframes, which define required content and broad flow only.

Do not copy the old wireframe visuals, YARDY branding, placeholder text, typos, duplicated pages, or role-mixed controls. Preserve the user need represented by a wireframe, then create a clean mobile-first OctoGear experience.

## Repository and ownership

- Flutter repository: `C:\Tamkkun\OctoGearProject\octogear`
- Laravel API repository: `C:\Tamkkun\OctoGearProject\OctoGear-api`
- Wireframes: `C:\Tamkkun\OctoGearProject\WireFrame`
- Brand guide and login reference: `C:\Tamkkun\OctoGearProject\wireframe and loging example`

Flutter and Laravel are separate repositories. The Flutter Git history and GitHub repository must contain Flutter work only. Laravel may be changed when an approved product/API gap requires it; do not copy Laravel into the Flutter repository.

## Current migration status

- Android Firebase is configured and verified for project `octogear-1d72b` and Android package `com.octogear.app`.
- Firebase Core, Messaging, Crashlytics, and Analytics initialize on Android; an FCM token was retrieved on an emulator.
- The official Android FlutterFire configuration has been generated.
- iOS Firebase, bundle ID migration, Apple signing, and iOS device verification remain required before an iOS release. Do not claim iOS Firebase support until they are complete.
- The existing Flutter code, assets, routes, theme, translation files, and package name still contain legacy Sahala/YARDY material. Replace it deliberately during the foundation migration; do not reuse it as OctoGear product logic.
- The last verified Flutter test run passed six tests. Static analysis has no compilation errors but has legacy style/unused-import findings that must be removed as the old scaffold is replaced.

## Brand and design system

Use the supplied OctoGear identity, not the legacy YARDY/Sahala assets.

| Token | Value | Use |
| --- | --- | --- |
| OctoGear navy | `#242C41` | Primary brand surface, text, navigation, dark backgrounds |
| OctoGear yellow | `#F7C83C` | Primary call to action, highlights, active state |
| Structural gray | `#878380` | Secondary/supporting detail only |
| Success | Green semantic token | Confirmed success, never a replacement for the primary brand |
| Warning | Amber semantic token | Caution/action required |
| Error | Red semantic token | Error/destructive action |
| Information | Blue semantic token | Informational state |
| Accent | Purple semantic token | Exceptional emphasis only |

Use the octopus, gear, and spark-plug logo exactly as supplied. Do not distort it, add effects, recolor it outside approved variants, or use low-contrast combinations. Before release, store approved high-resolution app-icon, splash, light, and dark logo assets in the Flutter assets directory.

Use Noto Sans Arabic as the primary brand font. It must render Arabic well and work consistently in bilingual layouts. UI must prioritize readable text, sufficient contrast, 44-48 dp minimum touch targets, safe areas, dynamic type, semantic labels, and clear loading/empty/error states. Use the navy base with yellow as an action accent, not as body text or a decorative substitute for hierarchy.

The login reference establishes the intended tone, not an exact page to copy. Correct its Arabic copy to:

> أهلاً بك في أوكتوجير. أدخل رقم جوالك للبدء.

The English equivalent is:

> Welcome to OctoGear. Enter your mobile number to get started.

Saudi phone formatting must use `+966` only if that is the confirmed market rule. The current backend normalizes Saudi mobile numbers, so the first implementation will use `+966` with a nine-digit number beginning with `5`.

## Localization and RTL contract

The application supports exactly these initial locales:

| App locale | API header | Layout direction |
| --- | --- | --- |
| Arabic (`ar`) | `Accept-Language: ar` | RTL |
| English (`en`) | `Accept-Language: en` | LTR |

Rules:

1. Every user-visible Flutter string belongs in `assets/translations/ar.json` and `assets/translations/en.json`. Never hard-code Arabic or English UI text in widgets.
2. Static app content is translated by Flutter. Localized names, server messages, cities, components, stores, and other API data are returned by the backend and must not be translated again by Flutter.
3. Persist the selected locale locally. On a language switch, update the app locale/direction immediately, update the API locale resolver, invalidate locale-dependent cached/reference data, and refetch visible server data.
4. Attach the exact `Accept-Language` header to every API request through one shared Dio interceptor. Repositories must not attach it individually.
5. Use directional APIs: `EdgeInsetsDirectional`, `AlignmentDirectional`, `BorderRadiusDirectional`, and directional icons where appropriate. Do not hard-code left/right for layout.
6. Format dates, numbers, price, and plural text using the active locale. Currency rules must be confirmed with the product owner before checkout is implemented.
7. Phone numbers, OTPs, IDs, license plates, and money values must remain readable within RTL screens. Use appropriate text direction/formatters rather than reversing raw values.

## Architecture

Use Riverpod as the single dependency and state-management system. Do not retain both GetIt and Riverpod as parallel service locators in the OctoGear implementation. Dependencies are provided through Riverpod providers and overridden in tests.

```text
lib/
├── app/                         # Bootstrap, root app, router, app-level providers
├── core/                        # Cross-feature technical infrastructure only
│   ├── api/                     # Dio, interceptors, typed API envelope, failures
│   ├── configuration/           # --dart-define/flavor configuration
│   ├── design_system/           # OctoGear tokens, theme, shared primitives
│   ├── localization/            # Locale persistence, API locale resolver
│   ├── logging/                 # Redacted AppLogger and Crashlytics integration
│   ├── network/                 # Connectivity/retry policy when needed
│   ├── routing/                 # Typed route declarations and guards
│   ├── storage/                 # Secure session storage and non-sensitive preferences
│   └── widgets/                 # Small, generic, reusable UI only
└── features/
    ├── authentication/
    ├── account/
    ├── customer_garage/
    ├── storefront/
    ├── part_requests/
    ├── orders/
    ├── provider_onboarding/
    ├── provider_inventory/
    ├── conversations/
    ├── notifications/
    ├── ratings/
    ├── payments/
    └── support_and_legal/
```

For an API/business feature, use this shape:

```text
feature/
├── data/
│   ├── data_sources/            # API calls only
│   ├── models/                  # JSON DTOs only
│   └── repositories/            # DTO mapping and API error translation
├── domain/
│   ├── entities/                # App/business objects when distinct from DTOs
│   ├── repositories/            # Contracts
│   └── use_cases/               # One business action/query per use case
└── presentation/
    ├── controllers/             # Riverpod Notifier/AsyncNotifier providers
    ├── screens/
    └── widgets/
```

Keep the dependency direction:

```text
presentation -> domain -> data -> core
```

A simple static legal screen does not need artificial repository/use-case layers. Do not create a generic `users` feature or a controller-style mega-feature. A feature is organized by a coherent user capability and its API/use cases.

## Feature boundaries and planned order

Build one bounded slice at a time. A phase is complete only when its screen behavior, loading/error states, tests, documentation, and verified API contract are complete.

1. **Foundation and application shell**
   - Rename Dart/package/app branding to OctoGear.
   - Replace the legacy theme, assets, translation files, router, configuration, and shared UI primitives.
   - Set up Android/iOS-safe bootstrap, Riverpod-only dependencies, locale persistence/header injection, typed failures, secure storage, logging, and route guards.
   - Configure iOS Firebase only after the iOS bundle identifier and Apple configuration are confirmed.
2. **Authentication and session**
   - Phone OTP send, verify, new-user registration, secure token storage, startup session restoration, logout, profile bootstrap, and role-aware shell.
   - This phase requires a role-neutral current-user endpoint before production completion.
3. **Account and customer garage**
   - Profile, language setting, saved-car create/read/update/delete, reference selectors, and empty/error states.
4. **Storefront discovery**
   - Store search/filter/pagination, store detail, store cars, component catalog/detail, ratings display, and saved-car-aware discovery.
5. **Part requests and order lifecycle**
   - Specific requests, general requests to multiple stores, offer display/selection, one state-driven order detail/timeline, cancellation, and customer receipt confirmation.
   - Do not implement this phase until the order/offer decisions below are approved and reflected in the API.
6. **Provider onboarding**
   - Provider application, commercial-registration proof, verified business contact, review/pending/approved/rejected states, role/capability rules, and resubmission.
7. **Provider inventory**
   - Provider stores, store cars, component CRUD, photos, price, warranty, stock, compatibility, and inventory history/availability.
8. **Provider orders and offers**
   - Incoming specific orders, general-request offers, order fulfilment, paid/completed history, refusal reasons, and order-related communication.
9. **Communication, notifications, ratings, support, and legal**
   - Conversation lists/messages/read state, notification inbox/taps, FCM token upload and delivery, rating flow, contact/support, approved terms/privacy/about content.
10. **Payments and release hardening**
    - Real payment provider integration, payment retry/refund behavior, pickup/delivery confirmation, iOS build/signing, Android release signing, accessibility, integration tests, and release checklist.

The exact implementation order may move only when an API dependency or an approved product decision requires it. Do not build a later feature as a fake shortcut around an earlier dependency.

## Confirmed API contract

The Laravel API base path is `/api`. All API calls send:

```http
Accept: application/json
Accept-Language: ar | en
Authorization: Bearer <Sanctum token>   # protected routes only
```

The standard API envelope is:

```json
{
  "success": true,
  "message": "Localized server message",
  "data": {}
}
```

Paginated endpoints additionally expose:

```json
{
  "meta": {
    "current_page": 1,
    "last_page": 3,
    "per_page": 15,
    "total": 42
  }
}
```

Use typed DTOs for this envelope and endpoint data. No `dynamic` or raw `Map<String, dynamic>` may escape the data layer. Parse field validation errors into a typed failure that can display field-level messages without exposing technical details.

Reference endpoints provide localized cities, companies, names, models, fuel types, colors, sections, and components. Cache reference data by locale, not as one language-independent value.

## Authentication and session contract

Confirmed public routes:

- `POST /auth/otp/send` with `{ mobile }`
- `POST /auth/otp/verify` with `{ mobile, otp }`
- `POST /auth/register` with `{ temp_token, full_name, city_id }`

Existing-user verification returns a Sanctum token, `is_new`, and a user type. New users receive a temporary token and must register.

Required rules:

1. Store access tokens only in secure storage. Never store access tokens, temporary tokens, OTPs, passwords, or payment data in shared preferences.
2. Add a shared authentication interceptor that reads the in-memory secure session and attaches the bearer token to protected calls.
3. Startup must show a neutral splash/session state. It must validate a stored token with a protected current-user endpoint:
   - no token -> authentication
   - valid token/current user -> role-aware application shell
   - 401 -> clear session -> authentication
   - timeout/no connection/5xx -> retain token and show a retry/offline state
4. Do not log out for 403, 404, 422, 429, timeout, or 5xx.
5. Logout must clear secure credentials, memory session state, and sensitive cached data.
6. The current backend has no role-neutral `GET /auth/me` or logout/revoke endpoint. Add and test them before declaring session restoration complete. The current API has no refresh-token behavior, so do not invent refresh logic.

## Error, offline, and request rules

All API-backed screens must explicitly handle:

```text
initial/loading
success with data
success with no data
validation/business error
network/timeout error with Retry
unexpected server error with Retry
```

| Condition | User behavior |
| --- | --- |
| 400 | Show safe backend message; do not retry automatically. |
| 401 | Clear invalid session only after the session rule above. |
| 403 | Keep session; show permission explanation. |
| 404 | Show resource no longer exists and a safe way back. |
| 422 | Preserve form input and show field errors. |
| 429 | Disable repeated submission; honor `Retry-After` when available. |
| 500-599 | Log technical context; show Retry; keep session. |
| No connection/timeout | Show offline/timeout UI and Retry; keep session. |

Never call an API from `build()`. Disable an action while its request is in flight. After `await`, verify `mounted` before navigation, dialogs, snackbars, or stateful UI work. Retry only safe idempotent reads unless the backend implements an idempotency key for a write.

## Order and offer decision gates

Do not create order, checkout, provider-offer, or payment screens that pretend these rules exist. The current backend/wireframes leave the following product decisions unresolved.

1. **Account roles:** Does one account retain customer capabilities while it applies for/is approved as a provider? Recommended: one account can have customer and provider capabilities; provider approval gates provider actions without removing customer access.
2. **Specific order:** A specific order starts `pending`, but a provider cannot quote/accept it and payment requires `negotiating`. Choose one:
   - listed component price is final, so customer can pay after stock confirmation; or
   - provider confirms/quotes, moving the order to negotiating before payment.
3. **General request:** Wireframes show a request sent to many stores. Recommended: many providers submit non-exclusive offers; the customer chooses one; accepting it reserves inventory and expires competing offers.
4. **Lifecycle:** Approve one canonical state machine and who can make every transition. Recommended baseline:
   `draft -> submitted -> negotiating/offer selected -> payment pending -> paid -> ready for pickup/shipped -> completed`, with `rejected`, `cancelled`, `expired`, `refunded`, and `disputed` as explicit terminal/exception states.
5. **Fulfilment:** Confirm pickup versus delivery, availability of delivery, verification/receipt behavior, operating hours, cancellation/refund policy, and whether a provider or customer confirms collection.
6. **General request details:** The current API has `model_id`, quantity, image, and notes but no requested component/section. Confirm whether component selection is required.
7. **Offers:** Fix server behavior so an accepted offer is marked accepted, competing offers close, rejected offers cannot be accepted, and edits stop after selection.

These decisions are business logic. Stop and obtain approval before changing affected Laravel routes or Flutter flows.

## Backend capabilities required before affected features

| Capability | Current state | Required action |
| --- | --- | --- |
| Production OTP | Codes are logged locally; no SMS gateway | Select and integrate an SMS provider. |
| Session validation/logout | No `/auth/me` or token revocation | Add role-neutral current-user and logout/revoke endpoints. |
| Media uploads | Image fields are string paths; no upload contract | Add secure multipart/signed-upload endpoint, validation, processing, and public/private URL policy. |
| Payments | Stub gateway; retry blocked after failed payment | Select a Saudi-compatible provider and fix payment attempt/retry/idempotency/refund behavior. |
| Push delivery | Device-token table exists; no registration/delivery | Add authenticated token register/remove endpoints, FCM/APNs sender, jobs, and notification deep-link payloads. |
| Chat | No read-mark endpoint/realtime transport | Add read status; choose polling or realtime; define order/store conversation permissions. |
| Provider stores | Company/gallery tables exist but no provider mutations | Add/update API and expose company/gallery data consistently. |
| Provider history | Paid list omits completed orders | Include completed provider sales/history. |
| CMS/settings | CMS routes bind numeric IDs; public settings missing | Define stable CMS keys and a public platform-settings contract. |

Before editing Laravel, write the exact problem, proposed data model/API contract, affected roles, state transitions, migration/backfill, validation, authorization, and tests. Apply the smallest approved backend change; do not refactor unrelated controllers.

## Provider and inventory rules

Use public terminology consistently:

- **Customer**: a person requesting or buying a part.
- **Provider**: a business-side capability in the domain.
- **Store owner**: the public-facing label for a provider managing a store.
- **Store**: a provider's marketplace listing.
- **Inventory**: store cars and components/stock.

A provider onboarding path must have explicit pending, approved, rejected, and resubmission states. Provider inventory must separate:

- store profile/company/location/contact
- store cars and vehicle compatibility
- components, condition, photos, part number, price, quantity, warranty, and status
- stock adjustment/history
- customer-specific requests/orders and general-request offers

Never expose provider inventory-edit actions in customer routes. Never expose provider accept/refuse controls in a customer order screen.

## Notifications and communication

Firebase initialization alone does not make product notifications work. When push becomes an approved feature:

1. Register the FCM token with the authenticated backend after login and on every token refresh.
2. Remove/disable it on logout.
3. Handle foreground messages, background messages, notification taps, and deep links.
4. Use non-sensitive notification text and localized payload/content.
5. Keep an in-app notification inbox with read/unread state as the reliable source of history.
6. Link order/chat notifications to typed routes only after authorization checks.

Chat must define participants, creation rules, message pagination, attachments, read state, blocking/reporting/moderation policy, and notification behavior before a production implementation.

## Testing and delivery standard

Before a feature is complete, include:

- Unit tests for validation, DTO mapping, use cases, failure mapping, locale header behavior, session behavior, and state transitions.
- Widget tests for loading, empty, validation, offline/retry, error, accessibility semantics, and success states.
- Integration tests for critical journeys: OTP/session restore, saved-car CRUD, part request/order lifecycle, and payment outcome when available.
- `flutter analyze` and `flutter test` run before merging.
- CI running analysis and tests on every pull request once the repository workflow is established.

For every feature, add a short implementation note to this document or linked feature document before coding:

```text
User action:
Roles/permissions:
API endpoint(s) and confirmed JSON example:
Loading/empty/error/offline states:
Navigation inputs/result:
Locale and RTL behavior:
Analytics/notification behavior:
Tests:
```

## Platform and release requirements

- Use `--dart-define` or flavors for dev, staging, and production. Never switch environments by editing source constants.
- All production API calls use HTTPS. Do not store backend secrets in Flutter.
- Android uses `com.octogear.app`. Configure a dedicated Android release key before Play distribution.
- Before iOS work, confirm the iOS bundle identifier, register it in Apple Developer and Firebase, add the correct `GoogleService-Info.plist`, regenerate FlutterFire options for iOS, and verify on an iOS device/simulator.
- Configure notification permission and actual delivery separately for Android and iOS.
- Verify Crashlytics reporting after a controlled non-production test and inspect Analytics in Firebase DebugView.
- Release only after testing major flows on physical Android and iOS devices, not only emulators.
- Never log tokens, OTPs, passwords, payment data, commercial-registration documents, raw phone numbers, or unnecessary personal data.

## AI-assisted change protocol

An AI assistant must:

1. Inspect relevant API, feature, existing tests, and this contract before coding.
2. State the bounded feature slice being changed.
3. Preserve the dependency direction and avoid unrelated cleanup.
4. Stop for product/API decisions that would materially change business behavior.
5. Update models/code generation after confirmed JSON changes; never hand-edit generated files.
6. Update this document when API contracts, routes, environment behavior, platform support, ownership, or feature decisions change.
7. Run proportionate tests and report what was verified, what is not verified, and any manual release step.

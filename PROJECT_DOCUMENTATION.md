# OctoGear - Mobile Application Development Contract

## Purpose

OctoGear is a production mobile marketplace for automotive spare parts. It serves people who need parts and store owners/providers who publish inventory and respond to requests. The mobile application must support Android and iOS, Arabic and English, right-to-left and left-to-right layouts, secure authentication, observable production behavior, and maintainable future changes.

This document is the source of truth for developers and AI assistants working in the Flutter repository. It replaces the old Sahala scaffold description. The old implementation is not part of the architecture or visual identity for OctoGear.

## Source-of-truth order

When sources disagree, use this order:

1. Explicit approved product decision from the project owner.
2. Confirmed Laravel API behavior and validated request/response example.
3. This development contract.
4. OctoGear brand guideline PDF.
5. Wireframes, which define required content and broad flow only.

YARDY is the historic label used in the wireframes for the same product; it is not a separate application. Preserve the user need represented by a wireframe, but do not propagate its historic label, placeholder text, typos, duplicated pages, role-mixed controls, or visual shortcuts into the final product. The final mobile product identity is OctoGear.

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
- iOS work and Firebase work other than Android first-time device-token capture and the approved staging Remote Config API URL bootstrap are deferred. Leave the existing Android Firebase project configuration intact; do not add notification delivery, permission, token-refresh, or iOS Firebase behavior. The selected environment resolves its API destination before the existing session flow starts.
- The old iOS bundle identifier, display name, and `GoogleService-Info.plist` are intentionally untouched while iOS is deferred. They must be replaced together with the confirmed iOS bundle identifier and new Firebase configuration before any iOS build or release; never copy the old Sahala Firebase identity into OctoGear.
- The legacy Sahala Flutter scaffold has been removed: its GetIt wiring, old routes, sample features, old login/OTP code, widgets, extensions, legacy storage/messaging wrappers, old Poppins assets, and obsolete tests are not part of OctoGear. The root Dart package and project lint package are named `octogear` and `octogear_lints`.
- The external YARDY wireframes remain unchanged as a functional product reference. They must never be deleted as part of Flutter source cleanup.
- Android launcher, Android splash, and the shared Flutter header use the approved full-color original OctoGear mark in `assets/icons/app_icon.png` and `assets/icons/splash.png`. These are high-resolution source crops from page 4 of the supplied brand guide; preserve their proportions and colors. A raw designer-exported SVG/PNG may replace those files later only after visual review. iOS icon/splash generation remains deferred with the rest of iOS work.
- The two local OctoGear safety rules (`avoid_debug_print` and `avoid_direct_storage_imports`) continue to run through `custom_lint`. Its plugin protocol is deprecated upstream, so plan a deliberate migration to `analysis_server_plugin`; do not remove the rules merely to silence tooling output.
- The last verified Flutter test run passed 142 tests (2026-10-02). Run `flutter analyze` and `flutter test` after every material foundation or feature change.
- The customer navigation now shows Home, Orders, Chats and More at `/customer`, `/customer/orders`, `/customer/chats` and `/customer/more`. The retained `/customer/stores` branch is hidden and guarded by the default-off `OCTOGEAR_STORES_ENABLED` build setting. Old `/customer/account` URLs, including saved-car child paths, redirect to `/customer/more`. Store discovery, car components, specific part requests, and order history/details remain implemented; Chats is a clearly labelled placeholder.

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

### Visual design contract

Wireframes and APIs define required content, states, roles, and flows. They do not prescribe the final visual layout. The login reference defines the intended mood: a calm light canvas, a clear OctoGear hierarchy, one focused white surface, generous readable spacing, and navy actions with restrained yellow emphasis.

Every future feature screen must follow these rules:

1. Reuse the shared OctoGear theme and generic visual primitives (OctoGearPageScaffold, OctoGearBrandHeader, OctoGearSurfaceCard, and feedback/status patterns) before creating a feature-specific visual component.
2. Keep business logic out of those generic UI primitives. API calls, Riverpod state, navigation decisions, validation, and role rules stay in the feature/controller/domain layers.
3. Design for Arabic first without breaking English: use directional layout APIs, allow text scaling, make form pages scroll safely above the keyboard, keep phone/OTP values LTR, and preserve at least 48 dp touch targets.
4. Use navy for hierarchy and primary actions; use yellow for focus, small emphasis, and selected/active detail. Do not use yellow body text on a white surface. Prefer white cards with a subtle border over heavy shadows or decorative clutter.
5. Give every page one obvious primary action, visible loading/disabled feedback, readable validation/error feedback, and a predictable Back, language, and sign-out action when that action is relevant.
6. The language control is a first-class utility: it must remain visible and understandable, switch layout direction immediately, and never be hidden behind an icon-only control when a label can fit.
7. Translate visible UI copy through the current `BuildContext` (for example, `context.tr('auth.continue')`) so it rebuilds correctly when the user changes language. Keep the operating-system app title as the fixed `OctoGear` brand name; it is metadata, not screen copy.
8. Do not crop the login JPG, regenerate, trace, recolor, or approximate the official OctoGear octopus logo. Use the approved full-color mark already stored in `assets/icons/app_icon.png` and `assets/icons/splash.png`; do not derive new logo variants from screenshots, wireframes, or the PDF. The native Android launcher/splash and shared `OctoGearBrandHeader` must use this one source of truth.

For every new feature, first implement its content/behavior contract, then apply this visual contract. A visually polished screen must never invent API behavior or hide an unresolved product decision.

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
7. Phone numbers, OTPs, IDs, years, and money values must remain readable within RTL screens. Use appropriate text direction/formatters rather than reversing raw values.

## Architecture

Use Riverpod as the single dependency and state-management system. Do not retain both GetIt and Riverpod as parallel service locators in the OctoGear implementation. Dependencies are provided through Riverpod providers and overridden in tests.

```text
lib/
├── app/                         # Bootstrap, root app, router, app-level providers
├── core/                        # Cross-feature technical infrastructure only
│   ├── api/                     # Dio, interceptors, typed API envelope, failures
│   ├── configuration/           # Remote Config URL bootstrap and environment
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

### Routing contract

Use one app-level `GoRouter` with generated typed route helpers. Do not scatter `Navigator` calls, raw `'/NameOfScreen'` strings, or role/session checks through feature widgets.

- Keep semantic paths in `core/routing/app_route_paths.dart`, for example `/auth/phone`, `/customer`, and `/provider`; a path represents a capability, not a widget class.
- Declare routes in `app/routing/app_routes.dart` and navigate with generated typed helpers such as `const PhoneSignInRoute().go(context)` and `const OtpVerificationRoute().push(context)`.
- Use `go` when changing a root/stateful destination that must not remain in the back stack (session loading, sign-in, customer shell, provider shell). Use `push` only for a child flow the user can return from (for example phone -> OTP -> registration, then later list -> detail -> edit).
- The central route guard observes the session controller and in-memory authentication-flow state. It alone maps loading, signed-out, unavailable, customer, and provider state to a permitted route. A backend remains the authority for every protected API action; a Flutter guard is only a safe UI boundary.
- Never put phone numbers, OTPs, access tokens, temporary registration tokens, passwords, or personal data in a route path, query parameter, log, or navigation argument. The short-lived authentication hand-off stays in an in-memory Riverpod controller.
- A screen may react to the result of its own user action through `ref.listen`, but it must not make global session redirects from `build()`.

## Feature boundaries and planned order

Build one bounded slice at a time. A phase is complete only when its screen behavior, loading/error states, tests, documentation, and verified API contract are complete.

1. **Foundation and application shell**
   - Rename Dart/package/app branding to OctoGear.
   - Replace the legacy theme, assets, translation files, router, configuration, and shared UI primitives.
   - Set up Android/iOS-safe bootstrap, Riverpod-only dependencies, locale persistence/header injection, typed failures, secure storage, logging, and route guards.
   - Configure iOS Firebase only after the iOS bundle identifier and Apple configuration are confirmed.
2. **Authentication and session**
   - Phone OTP send, verify, new-user registration, secure token storage, startup session restoration, logout, profile bootstrap, and role-aware shell.
   - This phase uses the shared role-neutral `GET /profile` endpoint for profile bootstrap before production completion.
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

### Environment configuration for the current phase

Approved 2026-10-04: select `development` (default, alias `dev`), `staging` or `production` (alias `prod`) using `--dart-define=OCTOGEAR_ENV=...` on run/build commands. Development and production URLs are manually edited in `lib/core/configuration/app_configuration.dart` (`developmentApiBaseUrl`, `productionApiBaseUrl`). The owner supplied `http://127.0.0.1:8000/api` for development; Android devices/emulators use `adb reverse tcp:8000 tcp:8000` to reach the PC, repeated after reconnection if needed. Production remains empty until supplied. Development accepts HTTP or HTTPS; production requires HTTPS. Neither reads Remote Config or cached API URLs. Invalid manual values show a bilingual configuration error and block API startup until rebuilt.

Startup resolves the environment configuration before constructing the existing Riverpod API/session tree. All URLs must be absolute and end in `/api`, without credentials, query or fragment. Android derives its release cleartext setting from the same environment argument to allow development HTTP; debug builds retain their existing tooling support. The Dio boundary, bearer token resolvers, locale headers, repositories and session validation remain unchanged.

Staging alone reads the Firebase Client Remote Config String parameter `api_base_url`, declared as `AppConfiguration.apiBaseUrlKey` in the same file. Staging requires HTTPS, such as a Cloudflare Tunnel URL exposing local Laravel. Publish the parameter and fully relaunch to use a new URL. Other Firebase services retain their current initialization; only the API URL source changes.

Staging uses a zero minimum fetch interval for launch-time updates, subject to Firebase throttling. The SDK fetch timeout is 10 seconds with a 12-second overall bound. On failure, use a validated activated value or saved staging URL. Malformed/empty values cannot overwrite the saved URL. A fresh staging install without a usable value shows the bilingual Retry screen. Development/production never fall back to staging. Configuration failures never clear session tokens.

The destination is immutable for each app launch. Tests cover environment routing, manual URL validation, no remote/cache access outside staging, staging timeout/fallback isolation, and bilingual configuration errors. The existing Android application/Firebase identity is unchanged and iOS remains deferred. These environment commands do not create separate side-by-side installations. See README.md for run/build commands, local networking, and staging publishing instructions.

## Authentication and session contract

Confirmed public routes:

- `POST /auth/otp/send` with `{ mobile }`
- `POST /auth/otp/verify` with `{ mobile, otp }`
- `POST /auth/register` with `{ temp_token, full_name, city_id, device_token? }`

Existing-user verification returns a Sanctum token, `is_new`, and a user type. New users receive a temporary token and must register.

During first-time registration only, Flutter may best-effort read the current Android FCM token and send it as the optional `device_token`. Laravel stores that nullable value in `users.device_token`. Token capture must never block registration: no token, timeout, or Firebase failure still creates the account. This is **not** notification delivery work: do not request notification permission, listen for token refreshes, store the token in Flutter, register existing-user tokens, remove tokens on logout, send Firebase messages, or add a notification endpoint in this phase.

Required rules:

1. Store access tokens only in secure storage. Never store access tokens, temporary tokens, OTPs, passwords, or payment data in shared preferences.
2. Add a shared authentication interceptor that reads the in-memory secure session and attaches the bearer token to protected calls.
3. Startup must show a neutral splash/session state. It must validate a stored token with protected `GET /profile`:
   - no token -> authentication
   - valid token/current user -> role-aware application shell
   - 401 -> clear session -> authentication
   - timeout/no connection/5xx -> retain token and show a retry/offline state
4. Do not log out for 403, 404, 422, 429, timeout, or 5xx.
5. Logout must clear secure credentials, memory session state, and sensitive cached data.
6. Session validation uses shared `GET /profile`, protected by `auth:sanctum`, `user.active`, and `auth.provider`. It returns the authenticated localized user profile and its `type` (`customer` or `service provider`). A valid customer opens the customer shell; a valid provider opens the provider shell.
7. After a successful profile read, cache the non-sensitive user profile locally for fast display. It is never proof of an active session: the token plus a fresh `GET /profile` response is the source of truth at every app launch.
8. The current API has no refresh-token behavior. Do not invent refresh logic. Local logout must clear secure credentials, in-memory session state, and the cached profile without being blocked by a network failure. Do not add an online token-revocation call until its Laravel route, authorization rule, and failure behavior are explicitly confirmed.

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

Unexpected Laravel exceptions on `api/*` routes must be reported only to server-side diagnostics and return a localized, safe `500` envelope. This applies even while local `APP_DEBUG` is enabled. Flutter must never render a server or unexpected failure message verbatim; it uses its own localized fallback instead.

## Order and offer decision gates

Do not create order, checkout, provider-offer, or payment screens that pretend these rules exist. The current backend/wireframes leave the following product decisions unresolved.

1. **Account roles:** Does one account retain customer capabilities while it applies for/is approved as a provider? Recommended: one account can have customer and provider capabilities; provider approval gates provider actions without removing customer access.
2. **Specific order:** A specific order starts `pending`, but a provider cannot quote/accept it and payment requires `awaiting_payment`. Choose one:
   - listed component price is final, so customer can pay after stock confirmation; or
   - provider confirms/quotes, moving the order to awaiting payment before payment.
3. **General request:** Wireframes show a request sent to many stores. Recommended: many providers submit non-exclusive offers; the customer chooses one; accepting it reserves inventory and expires competing offers.
4. **Lifecycle:** Approve one canonical state machine and who can make every transition. Recommended baseline:
   `draft -> submitted -> offer selected -> payment pending -> paid -> ready for pickup/shipped -> completed`, with `rejected`, `cancelled`, `expired`, `refunded`, and `disputed` as explicit terminal/exception states.
5. **Fulfilment:** Confirm pickup versus delivery, availability of delivery, verification/receipt behavior, operating hours, cancellation/refund policy, and whether a provider or customer confirms collection.
6. **General request details:** The current API has `model_id`, quantity, image, and notes but no requested component/section. Confirm whether component selection is required.
7. **Offers:** Fix server behavior so an accepted offer is marked accepted, competing offers close, rejected offers cannot be accepted, and edits stop after selection.

These decisions are business logic. Stop and obtain approval before changing affected Laravel routes or Flutter flows.

## Backend capabilities required before affected features

| Capability | Current state | Required action |
| --- | --- | --- |
| Production OTP | Codes are logged locally; no SMS gateway | Select and integrate an SMS provider. |
| Session validation/logout | Shared `GET /profile` returns the localized `UserResource` for active customers and providers. | Flutter must implement secure storage, startup validation, non-sensitive cached-profile storage, local session clearing, and role-aware routing. |
| Customer-car media uploads | Customer-car creation now accepts private multipart photos and returns authenticated image-stream URLs. It has a 24-hour exact-payload idempotency window and an hourly Laravel cleanup command. | Before production, configure and verify server-side image normalization/EXIF removal using an approved GD or Imagick-capable image worker; run Laravel's scheduler; set PHP/proxy upload limits; and make an explicit backup/backfill-or-retire decision for legacy raw picture data. |
| Payments | Stub gateway; retry blocked after failed payment | Select a Saudi-compatible provider and fix payment attempt/retry/idempotency/refund behavior. |
| Push delivery | First-time registration optionally stores one current-device token in `users.device_token`; there is no delivery, refresh, logout removal, or multi-device registration behavior. | Later define authenticated token register/remove endpoints, FCM/APNs sender, jobs, multi-device behavior, and notification deep-link payloads. |
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

### Registration city pagination (2026-10-04)

**User action and roles:** A new customer completing registration opens the city picker, searches for a city, optionally loads more results, and selects one city. The selected city and typed name remain in the form when the picker is dismissed.

**API contract:** Existing public `GET /api/reference/cities?search=...&page=1&per_page=50`, with localized `{id, name}` items and `meta: {current_page, last_page, per_page, total}`. Fetch exactly one page per initial load, search or Load more action. Laravel is unchanged; registration still sends the selected `city_id`.

**State and navigation:** The city selector is a modal picker, with loading, empty/search-no-results, failure/Retry and Load more states. Additional-page errors retain current results and retry the same page. Search is debounced and stale responses cannot replace a newer query. No automatic whole-list download or automatic error retries. Dismissal preserves the existing form selection; no authentication or route changes.

**Locale/RTL and tests:** Use localized Arabic/English labels and backend names, refresh results for locale changes, and support keyboard, scrolling and large text. Cover one-page requests, search/pagination, stale responses, retry, selection persistence and unchanged registration payloads. No analytics or notification changes.

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

## Next feature implementation note: authentication and session routing

**User action:** Open the application.

**Roles/permissions:** A tokenless visitor opens authentication. An authenticated customer opens the customer shell. An authenticated service provider opens the provider shell.

**API endpoint(s) and confirmed JSON example:** `POST /auth/otp/send` receives `{ mobile }`; `POST /auth/otp/verify` receives `{ mobile, otp }`; a new account then sends `{ temp_token, full_name, city_id, device_token? }` to `POST /auth/register`. `device_token` is a nullable best-effort FCM token and is not returned in a user resource. `GET /reference/cities` returns localized `{ id, name }` values for registration. Shared protected `GET /profile` returns the standard `{ success, message, data }` envelope where `data` is the localized `UserResource` and includes `type`.

**Loading/empty/error/offline states:** The authentication feature must show a neutral startup loading state while secure storage and profile validation run. For `401`, clear the token and open authentication. For timeout, no connection, and `5xx`, keep the token and show a retry/offline state. For `403`, keep the token and show the safe server message; do not route to login.

**Navigation inputs/result:** The typed app router is the only root routing decision-maker. It observes the session controller, which validates the token through `GET /profile`, caches the returned non-sensitive profile, then emits unauthenticated, customer, provider, or retryable unavailable states. Phone and OTP flow state is memory-only; a successful access-token write is followed by a fresh profile validation, and screens do not independently redirect from `build()`.

**Locale and RTL behavior:** The session request sends the current persisted `Accept-Language` value. The returned city/name is already localized by Laravel.

**Analytics/notification behavior:** Deferred for this phase.

**Tests:** Laravel feature tests for unauthenticated, customer, provider, and blocked shared-profile cases; Flutter unit tests for no-token, `401`, non-`401` failure, customer, provider, and profile-cache session outcomes.

### Phone sign-in error reset

**User action:** Edit the phone number after an OTP-send request fails.

**Roles/permissions:** Signed-out visitors; existing backend limits still apply.

**API contract:** Unchanged `POST /auth/otp/send` with `{ mobile }`.

**Loading/error behavior:** A text edit clears the previous send error without
sending another request. Selection changes alone retain the error. While a send
is pending, keep the phone field read-only so its displayed value matches the
submitted number. A timeout/no-connection failure relabels the unchanged
primary action as Retry, but it still requires an explicit user tap; never
automatically resend an OTP when connectivity appears to return. A subsequent
failed submission displays its own error.

**Navigation, locale, and analytics:** Editing never navigates. Successful send
navigation and bilingual error messages keep their existing behavior. No new
analytics or notification behavior.

**Tests:** Widget regression coverage for clearing a failed request message on
edit, preserving it on selection changes, and displaying a new failure on retry;
verify that an in-flight send keeps the number read-only.

## Customer navigation and More (2026-09-30)

**Approved bounded slice:** Home → Orders → Chats → More. Preserve Storefront and specific-request implementations for a later release. No Laravel, schema, buy/pay, authentication or SMS changes in this slice. Order filters and creation behaviour remain as previously implemented until the next approved batch.

**Visibility:** `customerStoresEnabledProvider` reads `OCTOGEAR_STORES_ENABLED`, default false. The same setting controls the Stores navigation destination, global redirects for every Stores descendant (including specific-request deep links), and the empty-orders browse action. Build with `--dart-define=OCTOGEAR_STORES_ENABLED=true` to restore the retained destination and journey. This is release visibility, not API authorization. Retained branches are not eagerly loaded.

**More:** A profile summary and working typed links to Profile, My cars and Settings, plus the existing session logout action. Profile displays the authenticated session's name, city and phone; profile editing is outside this batch. Settings uses the existing persisted app-language controller. No invented preferences or inactive menu buttons. My cars keeps its existing API-backed list/create/detail/edit flows under `/customer/more/cars`. Old account URLs redirect with their child suffix and query preserved. Tab switching preserves child navigation and form state; reselecting a tab does not discard a form.

**Chats:** Translated Coming soon screen with language action and existing brand styling. No messaging API, notification subscription, fake conversations or message composer.

**Verification:** 130 Flutter tests passed; static analysis and custom lint are clean. Coverage includes all visible destinations, the restored Stores journey with its flag enabled, hidden Stores deep-link redirects, legacy account/My cars redirects, More-to-profile/garage/settings navigation, child-stack preservation across tab switches, language switching, sign-out routing and narrow Arabic layouts at 1.8 text scale. The final Android build is installed on the emulator; visual checks covered Arabic More, English settings and Chats, plus language switching without leaving the settings page. Screenshots are under ignored `build/more-ar.png`, `build/settings-en.png` and `build/chats-en.png`. Laravel files from the previous order-history work remain untouched in this batch.

**Next batch:** Complete general-request creation across Flutter and Laravel: saved or request-only vehicle details, transmission, searchable catalog/custom component choice, quantity and optional photos. General-only order filters, provider offers/photos, acceptance/payment and chat integration are later bounded steps; preserve the underlying specific-order system.

## Original navigation shell implementation record (superseded by the update above)

**User action:** An authenticated customer opens the application or selects one of the four primary destinations.

**Roles/permissions:** Customer only. The session route guard permits the `/customer` route family only for a verified customer; a provider is redirected to `/provider`.

**API endpoint(s) and confirmed JSON example:** None. This shell must not fetch, cache, or fabricate Home, Storefront, Order, or Account data.

**Loading/empty/error/offline states:** Not applicable to this static navigation slice. Each later feature owns its required API states and replaces the matching temporary shell content.

**Navigation inputs/result:** Use one typed `StatefulShellRoute` with branches `/customer`, `/customer/stores`, `/customer/orders`, and `/customer/account`. Tab selection calls `StatefulNavigationShell.goBranch`, preserving every branch's future navigation stack and scroll state. Do not use raw paths or `Navigator` calls in tab widgets.

**Locale and RTL behavior:** Navigation labels and temporary explanatory copy are translated through `BuildContext`. The Material 3 `NavigationBar` follows the active layout direction, has always-visible labels, and retains 48 dp-or-larger interactive targets.

**Analytics/notification behavior:** Deferred. The shell does not create notification or analytics events in this phase.

**Tests:** Verify the four English and Arabic navigation labels, route/tab switching, RTL direction, and that the session guard allows verified customers inside the customer route family while redirecting providers away from it.

## Next feature implementation note: customer saved-car list

**User action:** A signed-in customer opens Account and selects **My cars**.

**Roles/permissions:** Customer only. The central session guard permits the `/customer/account/cars` child route for a verified customer. Laravel remains the authority: the endpoint uses Sanctum authentication, the active-user rule, and the customer rule, and returns only cars owned by that customer.

**API endpoint(s) and confirmed JSON example:** Protected `GET /customer/customer-cars`, using the standard envelope and the central bearer/locale headers. `data` is a newest-first, non-paginated list of objects containing `id`, `manufacturing_year`, nullable `transmission_type`, localized top-level `company`, localized `car_name`, localized `color`, localized `fuel_type`, typed `pictures`, and `created_at`. Flutter maps transmission to `transmissionType` (`manual`, `automatic`, `unknown`, or null). Each picture is controlled metadata with an exact API-relative owner-only stream URL, MIME type, size, and sort order—never a storage path, base64 value, or arbitrary host URL. Flutter rejects unexpected URLs before attaching a bearer header, renders an authenticated thumbnail for a valid first picture, and uses a neutral vehicle fallback when none can load.

**Loading/empty/error/offline states:** Render compact skeleton cards while loading, a truthful empty state when the returned list is empty, and a safe inline error with an explicit Retry action for no connection, timeout, server, permission, and unexpected failures. No failure clears a valid session. This safe `GET` may be manually refreshed; the feature explicitly disables Riverpod's default automatic retry and has no pagination because the API provides the customer’s complete personal saved-car list.

**Navigation inputs/result:** Account uses the generated `CustomerCarsRoute` helper to push the typed child route `/customer/account/cars`. The Back action returns to Account. My Cars pushes `CreateCustomerCarRoute` for the real `/customer/account/cars/add` child flow. A confirmed creation pops with `true`; the list then shows safe confirmation and refreshes from Laravel. A card pushes the typed detail route with its numeric ID only; when that detail flow returns for any reason, the list refetches Laravel truth so a completed edit, an uncertain deletion, or a concurrent change cannot leave a stale card. The customer StatefulShell remains visible.

**Locale and RTL behavior:** All static copy is translated from the app translation files through `BuildContext`. The centralized `Accept-Language` header returns localized car, color, and fuel names. The controller observes the app locale so a visible list reloads with the selected language. Transmission labels are localized in Flutter.

**Analytics/notification behavior:** Deferred. No event, notification, or device-token behavior is introduced.

**Tests:** Cover the authenticated endpoint path/header and DTO mapping; private-media URL validation and same-origin bearer protection; controller success, empty, error/retry, and locale reload behavior; Account-to-My-Cars typed navigation; and screen loading, empty, error/retry, populated-card, image fallback, Arabic, and RTL states.

## Next feature implementation note: create customer car with private photos

**User action:** A signed-in customer opens **My cars**, selects **Add car**, chooses the vehicle information, optionally selects up to five gallery photos, and submits once.

**Roles/permissions:** Customer only. Laravel remains the authority for every operation through Sanctum authentication, active-user and customer middleware, and the `CustomerCarPolicy`. A customer may access only their own cars and their own photo bytes. A nested photo that belongs to another car must return `404`, not leak its existence.

**API endpoint(s) and confirmed JSON example:** The form reads localized, public reference data from `GET /reference/companies`, `GET /reference/companies/{company}/names`, `GET /reference/colors`, and `GET /reference/fuel-types`. Company is a selector helper only; the persisted request sends `car_name_id`, `manufacturing_year`, optional `transmission_type`, `color_id`, and `fuel_type`.

`POST /customer/customer-cars` is a protected `multipart/form-data` request. It sends those fields plus zero to five `pictures[]` image files and one UUID `Idempotency-Key` request header. Flutter creates a new key after any draft edit and reuses the exact submitted key only for its explicit Retry action. Laravel records a server-only fingerprint of the scalar values and image bytes/MIME/order: within the configurable 24-hour window, the exact same request replays the original car; the same key with changed data returns a safe `409`; a soft-deleted or expired record never replays. Laravel's hourly `customer-car-media:purge-expired-idempotency-keys` scheduler command clears expired retained keys.

Laravel validates JPEG, PNG, or WebP files, a maximum of 5 MiB and 4096 x 4096 pixels per photo, stores random names on a private filesystem disk, and records only controlled metadata. No client storage path, disk name, original filename, server fingerprint, idempotency key, EXIF data, base64 value, or image bytes appear in JSON or logs.

The response/list shape contains typed picture metadata, for example:

```json
{
  "id": 9,
  "pictures": [
    {
      "id": 17,
      "url": "/api/customer/customer-cars/9/pictures/17",
      "mime_type": "image/jpeg",
      "size_bytes": 348291,
      "sort_order": 0
    }
  ]
}
```

`GET /customer/customer-cars/{customerCar}/pictures/{picture}` returns the authenticated owner the actual binary image stream with the correct content type. Flutter accepts only the documented `/api/customer/customer-cars/{car}/pictures/{picture}` relative path, resolves it on the configured API origin, and sends the bearer header; it never exposes the token in a URL or sends it to another host. Dedicated authenticated add/delete-photo endpoints may be used by a later edit-car slice. The current slice creates photos with the car and removes selected local photos before submission only. Adding photos to an existing car must preserve the total five-photo limit and return field-level `pictures` validation feedback when it would exceed it.

**Loading/empty/error/offline states:** Reference selectors have loading, empty, error, and explicit Retry states. The form preserves valid input and selected local photos after `422` validation, connection, timeout, and server failures. Submit is disabled while the multipart request is in flight. Network failures are not blindly retried; the visible Retry reuses the form's idempotency key. A success returns to My Cars and refreshes its list. The list displays a secure thumbnail when a returned picture can be loaded and a neutral vehicle fallback otherwise.

**Navigation inputs/result:** My Cars pushes a typed Add Car child route. Add Car pops with a created result only after a confirmed response; My Cars then reloads. No raw route strings, temporary data, or fake model selector may be used. The wireframe's model field is not implemented because the confirmed customer-car API has no `model_id`.

**Locale and RTL behavior:** All static copy is translated through `BuildContext`; reference names are localized by the API's shared `Accept-Language` header. Changing locale reloads reference lists without losing selected IDs where still available. Year fields remain readable left-to-right inside Arabic UI. The image picker is gallery-only in this slice; Android lost-picker-data recovery is handled so an activity restart does not silently discard selected photos.

**Analytics/notification behavior:** Deferred. This slice adds no Firebase, notification permission, background upload, SMS, or external service behavior.

**Tests:** Laravel feature tests cover multipart creation, metadata/path secrecy, file validation, exact-payload idempotency/replay/conflict/expiry, retained-key purge scheduling, storage rollback cleanup, force-delete cleanup failure, owner-only streaming, nested-resource ownership, and localized errors. Flutter tests cover multipart fields/headers/files, typed picture decoding, private-media URL safety, references and dependent company/name selection, form validation/retained draft, photo limits/removal, loading/error/retry/idempotency behavior, successful list refresh, image fallback, accessibility, Arabic, and RTL.

## Next feature implementation note: customer-car detail, edit, and removal

**User action:** A signed-in customer taps one of their saved cars, reviews its full information and all private photos, then may edit vehicle details or remove the saved car.

**Roles/permissions:** Customer only. Every endpoint remains protected by Sanctum, active-user/customer middleware, and the existing `CustomerCarPolicy`. A user may never inspect, update, remove, add a photo to, or delete a photo from another customer's car. A permission denial must not expose private car fields, pictures, storage paths, or media bytes.

**API endpoint(s) and confirmed JSON example:** `GET /customer/customer-cars/{customerCar}` returns one owner-authorized car. Its resource includes localized top-level `company`, `car_name`, `color`, `fuel_type`, full ordered private-picture metadata, and the persisted scalar values. `PATCH /customer/customer-cars/{customerCar}` receives only scalar JSON fields (`car_name_id`, `manufacturing_year`, nullable `transmission_type`, `color_id`, and `fuel_type`); the Flutter domain names stay clear even while those existing transport keys remain unchanged. `DELETE /customer/customer-cars/{customerCar}` soft-removes the saved car from customer lists. It is not presented as permanent deletion because private-media retention/purge policy is a separate operational requirement. Existing add/delete-photo endpoints deliberately remain unused by this slice: photo upload has no idempotency contract yet, so an uncertain retry could duplicate an image; photo removal needs an equally explicit retry/confirmation contract. The detail gallery is read-only until that separate safety work is approved.

**Loading/empty/error/offline states:** The detail screen has explicit loading, not-found, permission, retryable network/server error, and successful states. It fetches a fresh detail resource instead of trusting the list card as a full record. Edit retains unsaved scalar changes on validation/network/server failure. Scalar save is explicit and disabled while in flight; do not make one opaque multipart PATCH. Car removal requires a clear destructive confirmation and never happens automatically. A `404` after a stale card returns to My Cars with a truthful message. After an uncertain removal timeout/no-connection/5xx result, keep the detail visible and offer **Refresh**, not an automatic or blind DELETE retry; the customer may make a new deliberate removal decision only if the refreshed car still exists.

**Navigation inputs/result:** A list card pushes the typed child route `/customer/account/cars/:carId`; it passes only the numeric identifier. Detail can push a typed edit child route. A successful scalar edit pops back to detail with refreshed server data. A confirmed removal pops to My Cars with `true`, and the list explicitly reloads. Do not pass a token, photo bytes, file paths, or mutable car object through a route.

**Locale and RTL behavior:** Static copy uses `BuildContext` translations. API names/localized company follow the shared `Accept-Language` header. The detail view refreshes locale-dependent data when the language changes. Plate values and manufacturing years remain left-to-right. Photos use only the existing authenticated same-origin image component; no raw storage path or bearer token enters a URL.

**Analytics/notification behavior:** Deferred. This slice adds no Firebase work, background upload, or notification behavior.

**Tests:** Laravel covers localized company, active-reference validation, owner detail/update/delete authorization, missing/stale resources, and soft removal. Flutter covers typed DTO/repository mapping, route/card tap, detail loading/error/photo gallery, edit validation/save, destructive removal confirmation, list refresh, private image fallback, and Arabic RTL behavior.

## Next feature implementation note: customer storefront discovery

**User action:** A signed-in customer opens the **Stores** tab, browses active stores, searches by store nickname, and optionally filters by city and supported vehicle manufacturer.

**Roles/permissions:** Marketplace browsing is read-only and is protected by Sanctum and the active-user rule. Laravel decides which stores are active. The customer never receives provider-only management actions or provider private data. The browse response exposes only customer-needed listing data: store identity/display name, localized city, controlled store-picture stream metadata, rating, and sales summary. Mobile number, employee name, commercial-registration data/image, and owner-only location-management data remain available only to the owning provider. A later store-detail/contact feature must explicitly define which contact/location fields are public.

**API endpoint(s) and confirmed JSON example:** `GET /stores?query={nickname}&city_id={id}&company_id={id}&page={n}` is an authenticated, localized, paginated read. `query`, `city_id`, and `company_id` are optional; Laravel validates filters and returns active stores only, with `{ data: [...], meta: { current_page, last_page, per_page, total } }`. Public localized reference lists come from `GET /reference/cities` and `GET /reference/companies`. Store picture URLs must be accepted only when they match the documented same-origin API media path `/api/media/stores/{store}/pictures/{picture}`; Flutter attaches the current bearer header through the existing authenticated-image component and never places a token in the URL.

**Loading/empty/error/offline states:** Show accessible skeleton cards for an initial load, a clear empty state for the unfiltered marketplace or an active filter with no matches, a safe inline retry state for initial failure, pull-to-refresh, and an inline retry footer if a later page fails. Debounce nickname input for 400 ms, cancel it when the screen is disposed, and reject stale response results so an earlier query cannot overwrite a later query. Do not auto-retry reads. Prevent duplicate page fetches and stop after `last_page`.

**Navigation inputs/result:** This bounded slice replaces only the static `/customer/stores` shell preview. Store cards intentionally do not fake a detail flow; the typed store-detail route, store cars, and components belong to the next storefront slice.

**Locale and RTL behavior:** All static copy is translated through `BuildContext`. The central `Accept-Language` header localizes city/company names; switching language reloads the current query and filter options. All spacing/icons are directional and filter controls remain usable with Arabic text scaling.

**Analytics/notification behavior:** Deferred. This slice adds no notification, location-permission, map, call, or analytics behavior.

**Tests:** Laravel covers active-only search/filter/pagination and customer-safe response fields. Flutter covers pagination envelope decoding, exact endpoint/query/header behavior, invalid media URL rejection, controller first-page/filter/next-page/error behavior, and loading/empty/error/Arabic/card UI states.

## Next feature implementation note: customer store and inventory overview

**User action:** A signed-in customer selects an active store card and reviews the store’s public identity, supported vehicle manufacturers, gallery, and the first pages of its available vehicles.

**Roles/permissions:** Marketplace viewing is read-only for authenticated active users. A store that is inactive is not a marketplace resource: every shared store-detail, store-car, and nested-store read must return the same safe `404` result rather than exposing an inactive store by an ID guessed outside the listing. Provider management uses its separate provider routes; no customer route exposes `can_manage`, editing, contact, commercial-registration, or private location-management controls.

**API endpoint(s) and confirmed JSON example:** Protected `GET /stores/{store}` returns the standard success envelope with only customer-safe detail data: `id`, `name`, `nick_name`, localized `city`, numeric `average_rating`, integer `sold_quantity`, ordered typed `pictures`, and localized `companies` as `{ id, name }`. The backend must load and serialize `companies`; Flutter must not infer them from search filters. Protected `GET /stores/{store}/cars?page={n}` returns a localized, paginated list of that active store’s inventory vehicles. Each card needs only `id`, `manufacturing_year`, localized `car_name`, localized `color`/`fuel_type`, typed store-car picture metadata, and `components_count`. Private paths, phone numbers, employee names, commercial registration data, and management flags must not enter the customer detail DTO or domain entity. Store image URLs must exactly match `/api/media/stores/{store}/pictures/{picture}`; inventory image URLs must exactly match `/api/media/stores/{store}/cars/{car}/pictures/{picture}` before Flutter attaches a bearer header.

**Loading/empty/error/offline states:** The public store header and the inventory list are independent reads. While both load, show accessible skeletons. If the store header succeeds but inventory fails, retain the header and show an inline inventory Retry. A successful empty inventory shows a truthful no-vehicles state. A detail `404` shows a safe unavailable state with a route back to Stores; a timeout/no connection/`5xx` keeps the session and offers explicit Retry. Pull-to-refresh reloads both safe `GET` resources. Inventory pagination prevents duplicate loads, stops after `last_page`, and retains earlier cards with a retry footer if a later page fails. No automatic retry is used.

**Navigation inputs/result:** A store card pushes the generated typed child route `/customer/stores/:storeId`, carrying only the numeric store ID. The route refetches authoritative Laravel data rather than receiving a mutable card object. The Back action returns to the existing Stores tab. Inventory cards now push the typed car/components child route described below.

**Locale and RTL behavior:** Static copy is translated through `BuildContext`; Laravel localizes city, companies, vehicle names, colors, and fuel types via the shared `Accept-Language` header. Both detail and inventory providers observe app-locale changes and refetch localized server truth. Layout uses directional spacing and icons. Years remain left-to-right; the customer UI does not surface inventory license plates.

**Analytics/notification behavior:** Deferred. This slice adds no map/call action, contact sharing, notification, Firebase, or analytics behavior.

**Tests:** Laravel covers localized company output and blocks inactive stores from shared detail/inventory reads. Flutter covers trusted detail/inventory media decoding, exact authenticated endpoint/header behavior, independent detail/inventory states, pagination/retry behavior, typed card-to-detail navigation, gallery fallback, supported-company display, and Arabic RTL layout.

## Customer order history and details (2026-09-29)

**Approved slice:** Replace the Orders placeholder with customer-owned history and detail views for both `specific` and `general` orders. Read-only tracking and offer display are authorized here. General request creation, offer selection/rejection, cancellation, receipt confirmation, provider screens and payment remain separate lifecycle slices.

**Contract:** Authenticated `GET /customer/orders?page=1&order_type=specific|general` (omit type for all) and `GET /customer/orders/{id}`. Server filtering applies before pagination; stable newest-first ordering, totals and explicit load-more. Customer list/detail eager-load localized part/car/store information, offer counts and actual paid amounts without payment tokens. Existing fields remain compatible. General requests may have no selected store, named inventory part, photo, offers or price; never invent them. Deleted catalog/store references remain readable with fallback copy.

**Prices/status:** Save a server-controlled `requested_unit_price` for new specific orders at creation under the existing inventory lock. No historical backfill guessing: older requests without a snapshot show a clearly labeled current listed total when available. General orders have no quantity; each provider offer is the whole-request total. Selected offers are identified by `accepted_offer_id`. A recorded paid amount takes precedence for historical payment display. No price calculation changes to the buy/pay route. The API `awaiting_payment` status is displayed as Awaiting payment; `not_selected` offers remain readable in history. Show current status and creation date, not fabricated milestone timestamps.

**Architecture/UI:** Typed numeric-ID detail route under the Orders shell branch; repository/DTO/use-case/Riverpod layers; navy/yellow cards, Arabic/English, RTL, accessible large text, refresh/loading/empty/error/retry and stale/disposed response protection. Notes/photos stay out of logs; photo URLs must match the exact authenticated order-media endpoint. Successful request creation invalidates history and offers a View request link. Verify API ownership, filters, pagination, both order types, absent/deleted relations, money, offers, protected photos; Flutter transport/controllers/navigation/widgets; full suites and Android visual checks.

**Authorization fix:** The shared order policy now verifies the provider role before allowing access to pending general marketplace orders. This prevents another customer from using the provider rule to read someone else's general order or its protected image. Legitimate provider access is preserved.

**Verification:** All 125 Flutter tests and all 340 Laravel tests (1,434 assertions) passed. Flutter analysis and custom lint, and PHP Pint checks, are clean. The additive price-snapshot migration is applied locally. Android checks against the local API covered store history/details and the general-request empty state; populated general requests and offers are covered by widget/API tests. Large Arabic text regression checks also caught and fixed wrapping in the existing request price summary. Buy/pay routes, payment stubs and SMS/test authentication remain unchanged.


## Customer request a part (completed submission slice)

Pricing clarification (2026-09-29): requests to a specific store use the listed fixed component price; there is no provider quotation or negotiated-price confirmation step for this flow. Customer history/details are the next approved slice above. Provider app work and purchase/payment integration remain separate future steps. The existing buy/pay route and SMS/test authentication stay as configured.

**Action and route:** Customer taps Request a part on an in-stock inventory component. Typed `/customer/stores/:storeId/cars/:carId/components/:componentId/request` loads the authoritative component and car/store context. The form accepts quantity, optional notes (1,000 characters), and one optional JPEG/PNG/WebP photo (5 MiB maximum), submitted as one entry in Laravel's `images[]` array. The listed component price is fixed for this store-specific flow, and submitting the request does not charge the customer. Success shows the request reference, links to its order details, and offers a secondary return to the car.

**API and permissions:** Authenticated active customer sends multipart `POST /customer/orders` with `order_type=specific`, inventory `store_car_component_id`, `quantity`, optional `notes` and `images[]`, plus a UUID `Idempotency-Key` header. Customer/store identity and price are never supplied by the client. Existing nested component GET verifies ownership; creation also checks active store, non-deleted car/component and current stock. Creation does not reserve/deduct stock or populate the legacy offered_price field. That existing API behavior does not imply a provider quotation step; future purchase integration must follow the fixed-price requirement. Existing private image storage and OrderCreated event are reused.

**Retry and errors:** Add nullable customer-scoped idempotency columns/index to orders, keeping older clients compatible. Same key and payload returns the original request without duplicate images/events, even if stock changes afterward; changed payload or deleted original returns 409. Keys last for the retained order lifetime. A failed/uncertain submission retains the exact in-memory command and key for explicit retry, blocks edits until resolved, and warns before leaving. No automatic write retries or offline queue. A terminated app loses the unsaved draft. Loading, unavailable part, field validation, photo errors, submitting and success have explicit states. Notes/photo response fields are redacted from app logs.

**UI and checks:** Existing navy/yellow theme, customer shell, Arabic/English translations, RTL, accessible controls, scrolling and large text. Reselecting a bottom tab preserves its route stack so it cannot silently discard a request; the page's back action owns draft confirmation. Unit/widget tests cover multipart mapping, retry/double-submit behavior, validation and localized form/success; API tests cover authorization, availability, private photo storage and idempotency. Deploy the new additive migration before the updated client.

**Existing event registration fix:** Live verification exposed duplicate store notifications: Laravel discovered the listeners already explicitly mapped in `EventServiceProvider`. Automatic discovery is now disabled and all explicit app event mappings are retained. A real-listener API test verifies that only the target store receives one notification, including after a retry. This changes no buy/pay route, pricing or payment implementation. Rebuild deployment event caches after updating this configuration; existing historical notifications are not deleted.

**Verification (2026-09-28):** Flutter analysis and custom lint are clean; 112 Flutter tests verified across the regression run and corrected navigation rerun. Laravel: 334 tests, 1,377 assertions. The additive migration was applied to the local database and the final Flutter build installed on the emulator. Android inspection covered Arabic/English layouts and live request #61 (quantity 2): one pending request, final price null, no payment, stock unchanged. Screenshots are saved under ignored `build/part-request-ar.png`, `build/part-request-en.png`, and `build/part-request-success.png`. Optional photo upload and private access are covered by widget/API tests. Unsent drafts and retry references remain in memory only; app termination is not an offline submission queue.

## Customer inventory car and components

**User action:** Tap a vehicle in a store to review its photos, manufacturer, year, color, fuel type, section-condition report, and paginated parts. Each part shows its localized name/section, listed price, stock, part number, warranty, and description. This is a read-only catalog; ordering remains a separate phase.

**Roles/permissions:** Authenticated active marketplace users. Laravel validates the active store and nested car/component ownership. Customer car responses omit license plates and management flags. Missing or removed catalog references cannot crash or leak a component response.

**API endpoint(s) and confirmed JSON example:** `GET /stores/{store}/cars/{car}` returns the existing car fields plus localized `company`, public `store: {id, name}`, and `sections: [{section_id, name, condition: "okay"|"damaged"}]`. `GET /stores/{store}/cars/{car}/components?page=1` returns the standard pagination envelope with items such as `{id: 5, component: {id: 2, name: "Alternator"}, section: {id: 3, name: "Engine"}, price: 52000, currency: "SAR", price_scale: 100, stock_quantity: 2, part_number: "ALT-20", warranty_months: 3, description: null}`. Price remains the existing integer minor-unit amount used by PaymentService and demo fixtures; currency metadata makes display unambiguous (52000 = SAR 520.00). No checkout, tax, compatibility, component photos, or payment behavior is inferred.

**Loading/empty/error/offline states:** Independent car and component reads, accessible loading states, explicit retry, truthful empty and out-of-stock states, pull-to-refresh, and a Load more / Retry footer that preserves earlier parts. Reads never retry automatically; locale changes and refresh invalidate stale page results. Not-found responses give a safe Back to stores action.

**Navigation inputs/result:** Typed `/customer/stores/:storeId/cars/:carId`, numeric IDs only, within the existing customer shell. Back returns to the store and retains its browsing position. Gallery uses validated same-origin authenticated car-picture paths.

**Locale and RTL behavior:** Static labels in Arabic/English; locale-aware prices and quantities; ungrouped manufacturing years; LTR part numbers. Both reads reload server-localized names on language change. Layout supports small screens and large text.

**Analytics/notification behavior:** Unchanged. SMS logging, Firebase, registration, and payment stubs remain untouched.

**Tests:** Laravel contract, locale, soft-deleted references, pagination, authorization/nesting, and customer-safe fields. Flutter DTO and authenticated API mapping, price units, pagination/retry/stale response/disposal, typed navigation, independent loading/error/empty states, Arabic RTL and large-text layout. Run analysis and both test suites; visually inspect the new page.

### Customer-car media deployment and deletion safety

Before deploying this feature, run Laravel migrations, configure the production scheduler to invoke `php artisan schedule:run` every minute, and verify that the hourly customer-car idempotency cleanup command appears in `php artisan schedule:list`. Set PHP and reverse-proxy multipart size limits at or above the API's 5 MiB-per-image contract. Configure and test a GD/Imagick-capable normalization/EXIF-removal worker or approved image service before public production use; client compression is only a usability optimization, not a privacy control.

The legacy migration deliberately hides old raw picture values rather than guessing that their files are trustworthy. Before deploying against existing production data, take a backup and explicitly choose a tested private-media backfill or a customer-visible retirement path. Do not roll back the media migration after new private uploads exist. Eloquent `forceDelete()` cleans a car's private media first and aborts safely if storage cleanup fails. Any future account deletion, raw database maintenance, bulk deletion, or database-cascade path must first use an explicit media-purge lifecycle; never assume a database cascade removes private files.


## Flutter/API alignment — 2026-10-02

This maintenance slice aligns existing screens with the current Laravel contract; it does not add general-request creation, checkout, chat logic, or provider features.

- Saved-car create/edit/list/detail use optional `transmission_type` alongside the existing required car name, year, color and fuel. Plate fields and copy are removed. Customer-car photo uploads and private galleries are preserved.
- General-order history accepts responses with no quantity or car-model field, displays `vehicle_details` snapshots and catalog/custom component names, and treats every offer price as the whole-request total. Specific requests retain their quantity contract.
- `awaiting_payment`, `not_selected`, and `accepted_offer_id` map explicitly. Paid/completed offers remain visible through existing read-only details, including every returned order/offer photo and its protected URL.
- The retained specific request form submits its optional photo as `images[]`, and handles `images` / `images.0` errors. Its current single-photo UI remains intentionally unchanged.
- Existing list-based city/company/car-name selectors load all reference pages with `per_page=50` and validate page metadata. They do not silently accept a partial list after failure. Colors and fuel types remain unpaginated. This compatibility adapter preserves current selectors; an on-demand searchable/paginated picker is a separate UI step for larger catalogs.
- SMS/login, payment stub, routes, hidden-store navigation, Firebase configuration and Laravel source are unchanged by this slice.

## Customer Home presentation — 2026-10-02

Home now has a dedicated `customer_home/presentation` feature instead of the navigation placeholder. A compact greeting/logo header leads into the full-width promotional carousel, followed by a compact navy request panel and a label-width yellow button with a 48 dp minimum touch target. The request button now opens the three-step general request flow described below; it creates an order only after the customer reviews and submits it. The requests/offers card opens the existing typed Orders route. Live offer summaries and customer-specific empty/waiting states remain a separate integration step; Home makes no API requests and does not fabricate prices or offers.

The revised owner-supplied banners include embedded text and are bundled unchanged under `assets/images/home`. Both Arabic and English now have all three supplied banners, ordered parts, details, offers. The English parts banner was added on 2026-10-03; a fresh Android build is required to include the newly added asset in the installed app. All six Home banners are listed explicitly in pubspec.yaml; this also invalidates the stale generated bundle that omitted parts-en.png. The four Home widget checks pass with the completed English set. Language switching replaces the whole banner set and resets to its first page. Images retain their 2:1 aspect ratio with `BoxFit.contain`, without overlays, footer copy, cropping or RTL mirroring. Manual swiping, position indicators and accessible previous/next controls support navigation. Banners are display-only images: tapping does nothing, and there is no full-screen viewer or image button semantics. Localized semantic descriptions preserve screen-reader access to the text embedded in artwork. The compact request panel uses the same heading scale and spacing as the rest of Home, removes the decorative icon and long paragraph, and grows naturally with text scaling. Its button fits the label instead of stretching across the card. The existing Orders destination is presented as a compact clickable shortcut with an arrow; live order/offer summaries are still deferred.
Shared typography now bundles Noto Sans Arabic and Noto Sans from the official Google Fonts repository, including their SIL Open Font Licenses. The core theme selects the appropriate family by locale, including button styles; no font download is needed at runtime. The shared wordmark uses bundled Noto Sans while preserving the approved logo artwork and colors.

Verification covers the request availability sheet, navigation to Orders, banner swiping/controls, translation without leaving Home, and 320 dp Arabic/English layouts at 200% text scale. Visual previews use the bundled fonts and supplied artwork. Order creation, payment, provider behavior and Laravel are outside this presentation slice.

**Validation:** All 142 Flutter tests pass; Flutter analysis and custom lint report no issues. The Android debug APK builds successfully. Arabic/English rendered previews are available in ignored `build/home-*-top.png` and `build/home-*-banners.png` files. The build retains the existing Firebase plugin warning about future Kotlin Gradle compatibility.

## General part request flow — 2026-10-03

**User journey:** Home → Vehicle → Part details → Review → confirmed request. Each step appears separately and Back/Edit retain entered values. Customers choose a saved car or enter a request-only vehicle; an unchecked-by-default option saves a new vehicle to My cars only with successful submission. Reuses the garage reference providers/editor; transmission is required for an inline request vehicle, while the independent garage editor retains its optional contract. Part selection uses a searchable, explicitly paginated catalog or a custom name. Description and up to five photos are optional. No quantity, car model, price or store selection is added to general requests.

**Architecture and contract:** New `general_requests` feature separates domain command/repository/use case, API mapping, Riverpod submission state, component picker, photos and guided presentation. Typed `/customer/request` child route stays in the customer shell. Existing core API, theme, localization and shared feedback widgets are reused. Public `GET /reference/components?search=&page=&per_page=20` uses localized reference names. Authenticated multipart `POST /customer/orders` sends `order_type=general`, an UUID `Idempotency-Key`, exactly one of `customer_car_id`/`vehicle[...]`, and exactly one of `component_id`/`component_name`. Optional fields are `description`, `images[]`, and (for inline vehicles only) `save_to_my_cars`. Gallery selection reuses MIME/size/dimension checks and immutable photos from the existing request feature. Multipart logging exposes field names/counts, not user content or images.

**Failures and lifecycle:** No automatic write retries. Double taps are blocked. A timeout, connection/server error or malformed receipt preserves the exact immutable command/key for explicit retry; edits are locked until the outcome is confirmed. Validation and definite rejections preserve the draft and allow correction, with returned field errors visible at review. Conflicts cannot be resent. Cancel protects changed/uncertain drafts. Success requires a valid general-order ID, refreshes Orders and optionally My cars, and shows a confirmed reference with a typed View request action. State survives step and tab navigation within this running flow, but is not persisted across process death or sign-out; Android gallery lost-image recovery does not restore the whole form.

**Localization/accessibility:** Arabic/English static copy, locale-aware reference reloads, RTL layout, existing bundled Noto fonts, visible step progress, naturally expanding content and accessible controls. No payment or provider actions added. Live Home order/offer summary cards remain a later slice; the Home shortcut continues to open Orders.

**Verification:** Contract tests cover exclusive multipart payloads, authenticated locale/idempotency headers, response validation, immutable photo streams and retry behavior. Widget tests cover saved/inline vehicles, required validation, catalog/custom parts, stale search results/pagination, optional save, photo limits/removal, review/edit persistence, uncertain/422 errors, draft cancellation and large-text Arabic/English layouts. The local backend reference endpoint was checked read-only; no test order was created in the user's running database. Rendered previews use the bundled fonts and are saved under ignored `build/request-*.png`.

**Completed validation:** All 155 Flutter tests passed. Flutter analysis and custom lint report no issues. English/Arabic font-rendered previews pass, and the Android debug APK builds successfully. The existing Firebase Kotlin Gradle compatibility warning remains unchanged.

## Searchable vehicle selectors — 2026-10-03

Manufacturer and car-name fields now share `core/widgets/octogear_searchable_select_field.dart` across Add Car, Edit Car and the Vehicle step of a general request. Each field opens a searchable single-choice sheet above the app navigation, using the existing theme and translated labels. The selected manufacturer still scopes the car-name catalog; selecting a different manufacturer clears the old car name, while cancelling or reselecting the same manufacturer preserves it.

Search filters the complete localized reference lists already loaded across all API pages. It trims surrounding whitespace, ignores English case and normalizes Arabic vowel marks/alef variants. Clearing the search restores all options; no results has explicit translated feedback. Selection remains integrated with form validation, server errors, disabled submission states and parent-driven resets. The sheet expands when the keyboard is visible to keep results accessible at larger text sizes. No API contract changes or new packages are required.

Verification covers search inside both Add Car and new-request vehicle entry, Arabic matching, empty/clear/cancel/reselect behavior, controlled-value validation, disabled fields and keyboard/large-text layout. English/Arabic search previews are available in ignored `build/request-*-company-search.png` and `build/request-*-car-name-search.png` files.

**Search validation:** 29 focused widget tests passed across the shared selector, garage screens and general requests, plus two rendered Arabic/English preview checks. Flutter analysis and custom lint report no issues.

## General request presentation refactor — 2026-10-03

The general request screen now coordinates draft ownership, validation, step navigation and submission. Vehicle, part details, review, success, page layout and shared request feedback are separate stateless widgets under the feature's presentation/widgets directory. Feature-specific widgets remain inside general_requests; shared theme, feedback surfaces and garage selectors continue to use their existing locations.

Text/scroll controllers, form keys, selected references and photos remain owned by the parent screen, preserving the draft when steps are unmounted and revisited. The existing submission controller, immutable retry command, API payload and route behavior are unchanged. This is a responsibility-based extraction with no intended visual or user-flow changes.

Verification: all 25 focused request/shell tests pass, including an extended inline-vehicle test that revisits vehicle and part steps before submitting. Both Arabic/English rendered preview tests pass; all 12 generated screenshots match their pre-refactor files byte for byte.

**Refactor validation:** Flutter analysis and custom lint report no issues. The Android debug APK builds successfully; the existing Firebase Kotlin Gradle compatibility warning remains unchanged.

## Home recent requests — 2026-10-03

Home now shows up to three recent requests below the existing banners and compact request action. Each small, naturally sized card shows the requested part, vehicle, current status and (for general requests with offers) offer count. Pending general requests distinguish waiting for offers from offers received. Tapping a card opens its existing details route; View all opens Orders. Individual store/price offer previews remain a separate follow-up.

The Home screen keeps the existing customerOrdersProvider(all) subscription alive while the summary scrolls offscreen. It shares the Orders cache and successful-request invalidation, supports pull-to-refresh, and uses the authenticated localized order list without per-order detail calls or new API contracts. A sorted copy provides newest-first summaries without changing the shared paginated list. Loading, retryable failure and empty states are distinct. The empty message points to the existing request button rather than duplicating a large action.

HomeRecentRequests and HomeRequestCard stay in the Home feature. Existing core surfaces, colors, typography and localization remain shared. Cards expand for accessibility text sizes; directional layout and arrows work in Arabic and English. Checks cover summary limits/order, offer status/count, detail navigation, refresh/invalidation, loading/error/retry/empty states and 320 dp layouts at 200% text scale. Arabic/English previews are rendered with bundled fonts in ignored build/home-*-recent-requests.png files.

**Home summary validation:** All 161 Flutter tests pass, together with two rendered Arabic/English preview checks. Flutter analysis and custom lint report no issues. The Android debug APK builds successfully; the existing Firebase Kotlin Gradle compatibility warning is unchanged.

## Home offer previews — 2026-10-03

Home now places an Offers to review carousel above recent requests. Cards show store, requested part, request reference and explicitly labelled whole-request offer total, using the existing SAR/minor-unit formatter. Tapping opens the owning request details; View all opens Orders. Adjacent cards peek into view, with horizontal swiping, accessible previous/next buttons, RTL direction and reduced-motion support. Cards grow with text size rather than clipping into a fixed-height carousel.

The section reuses offers embedded in the existing authenticated order-list response, without new API calls, contracts or packages. It shows at most eight pending offers from pending general requests that have no selected offer, ordered by descending offer ID. Rejected, unselected, unknown and accepted offers, and closed/selected requests, are excluded from these available choices. This is explicitly a preview for recent requests: it uses the currently loaded Orders pages, not the entire account history. Older requests and their full offer history remain accessible through Orders. No extra empty panel appears when the loaded requests have no available choices; request cards retain their waiting/status feedback.

The shared Home refresh and order-cache invalidation refresh both sections. Feature widgets and preview selection remain inside customer_home, while core surfaces/theme and order currency/domain types are reused. Tests cover eligibility/limits, correct total price, owning-request navigation, Arabic/English swiping and controls at 200% text size. Font-rendered previews are in ignored build/home-*-offers.png files.

**Offer-preview validation:** All 34 focused Home/shell/order tests pass, and both Arabic/English rendered preview checks pass. Flutter analysis and custom lint report no issues. The Android debug APK builds successfully; the existing Firebase Kotlin Gradle compatibility warning remains unchanged.

## Clear request details and offer decisions — 2026-10-03

General-request details now presents a compact part/vehicle/status summary followed by offer previews. Full vehicle information, creation date, historical payment amount, request notes and submitted photos are under an expandable Request information section. Selected offers have a single summary; previous rejected/unselected offers are expandable. Empty selected-store/price panels no longer occupy the initial general-request view. Specific-order details retain their existing content in a separate widget, and the authenticated photo viewer is shared within the orders feature.

Home and request offer cards now open the same typed offer-details route (/customer/orders/:orderId/offers/:offerId). The offer page shows its own store, whole-request total, status, notes and images, with a link to the related request. Chat only navigates to the existing Chats tab: no thread or message is created. Accept uses a white/green outlined action and confirms the store, total and consequence for other offers. Acceptance does not invoke payment. Refuse opens a dedicated child page with deselectable optional preset reasons and an optional note; a reason is not required, and keeping the offer performs no write.

A feature-level actions repository uses the existing authenticated POST customer/orders/:orderId/accept-offer and POST customer/orders/:orderId/offers/:offerId/reject endpoints, with verified response IDs/statuses. Before sending, the controller reloads the request and checks offer membership, eligibility and the displayed price. Duplicate taps are blocked. Writes are never automatically retried; failures after a write begins require an explicit status refresh before another decision. Success and failures invalidate request details and the shared Orders/Home data. The reason is trimmed and omitted from the API payload when blank; notes allow up to 800 characters, leaving room within the backend's 1000-character limit for a preset reason. Existing API authorization and transaction rules remain authoritative. No backend or payment changes were needed.

The main detail route, general/specific content, photo viewer, offer/refusal pages and action feedback/controller are kept in focused feature files. Existing core surfaces, typography, status colors, localization and API handling are reused. Arabic/English screenshots for request, offer and refusal pages are generated with bundled fonts under ignored build/offer-flow-*.png. Tests cover confirmation/cancellation, optional refusal reasons, endpoint/receipt contracts, current-price checks, duplicate prevention, uncertain-result refresh, navigation to the exact offer/Chats, expandable request information and narrow 200% text layouts. Validation uses fake repositories and HTTP responses; no real customer offer was accepted or refused.

All 176 Flutter tests and both Arabic/English rendered preview checks passed. Rebuildable Android intermediates and an interrupted generator snapshot were cleared after the disk filled; source files and the previous APK were preserved. The new validation APK targets the connected x64 emulator to reduce disk usage.

**Offer-decision validation:** Flutter analysis and custom lint report no issues. The x64 Android debug APK builds successfully. The existing Firebase Kotlin Gradle compatibility warning is unchanged.

## Customer request editing and deletion — 2026-10-03

Request details now offers compact Edit and Delete controls based on server-provided eligibility. Edit opens a dedicated form: general requests allow part selection/custom name, description and a separate vehicle-details step reusing searchable garage fields. Store-specific requests allow quantity and notes while retaining the requested item and original unit price. Vehicle edits change only the request snapshot, not the saved garage. Existing request photos are retained. Unsaved form changes have a discard confirmation; deletion identifies the request and requires explicit confirmation. Arabic/English copy, core theme, accessible touch targets and large-text layouts are supported.

Laravel now provides authenticated PATCH and DELETE /api/customer/orders/{order}. CustomerOrderResource adds can_edit, can_delete and edit_token. Clients echo edit_token; the server locks the order, checks ownership through policy, then rechecks eligibility and the revision before mutating. Editing requires pending status, no accepted offer, no payment record and no offer history (including withdrawn offers). Deletion allows pending/rejected/cancelled requests only without an accepted offer or payment record. Deletion soft-deletes the request and its offers, retaining media metadata/history and the original creation idempotency key. Paid/completed/accepted requests cannot be deleted. No schema migration or payment change is required.

PATCH accepts optional general description, component_id OR component_name, and a complete vehicle object. As approved on 2026-10-04, customer_car_id is prohibited for updates: vehicle edits replace only the request snapshot, never a garage car. POST creation still supports customer_car_id or vehicle. Omitted part/vehicle fields preserve the original snapshot and saved-car reference, including retired references; an explicit vehicle replacement becomes a request-only snapshot. Specific updates accept quantity and notes, validating changed quantity against active stock. Images and identity/status/pricing fields are not editable through this endpoint. A stale token or changed eligibility returns 409; validation errors return 422. No automatic write retries occur. Uncertain outcomes require an explicit read before another attempt; 404 after an uncertain deletion reconciles as no longer available. Successful changes invalidate both request details and shared Orders/Home data. Regression tests cover rejected saved-car updates, unchanged snapshots on rejection/omission, manual edits without garage mutations, rollback and preserved saved-car creation.

The typed edit route is /customer/orders/:orderId/edit. Feature files separate API mapping, repository, mutation controller, edit form, vehicle draft and management feedback/actions. The backend reuses vehicle/component validation from general request creation. Tests use fake app repositories and an in-memory SQLite backend database; no real customer request is modified. Font-rendered review images are under ignored build/order-management-*.png.

Validation: all 191 Flutter tests pass, with clean Flutter analysis and custom lint. Both Arabic/English rendered previews pass. All 9 new backend tests pass (53 assertions); the earlier focused order/offer/history/specific-request run also passed 38 tests. Broader backend regression checks passed 42 tests with one unrelated existing failure: GeneralOrderDetailsTest expects 30 seeded general requests, while the pre-existing DemoDataSeeder changes now create 50. Those seed changes and the outdated assertion were left untouched. The Android x64 debug APK built successfully and was installed/launched on emulator-5554; the existing Firebase Kotlin Gradle compatibility warning remains unchanged.
## Local testing OTP display — 2026-10-03

The login send endpoint retains its existing local server logging and optionally returns the same four-digit code as data.test_otp. Exposure requires BOTH APP_ENV=local and OTP_EXPOSE_FOR_TESTING=true. The flag defaults to false in config/otp.php and .env.example; it is enabled in the current ignored local .env for the requested testing workflow. Production, staging and other environments omit the field even if the flag is true. The response uses Cache-Control: no-store, private. OTP hashing, expiry, verification, one-time consumption and throttling remain unchanged. Provider onboarding responses remain unchanged.

Flutter carries the nullable code through sendOtp into ephemeral authentication-flow state and displays a localized Testing code box above the normal OTP input only in debug development builds. Release/staging/production configurations do not retain or display it. The customer still enters and verifies the code normally. Resend clears the old testing code while pending, replaces it on success and leaves it hidden on failure. Codes preserve leading zeroes, stay out of routes/persistent storage, use existing OTP log redaction, and are cleared by authentication-flow completion/registration. Resend and verification cannot run together from the screen.

Validation: all 200 Flutter tests pass. All 25 focused Laravel authentication tests pass (129 assertions), covering local opt-in/out, production/staging gating, matching log/hash/code, resend, expiry and one-time verification. Widget tests cover Arabic/English at 200% text size and confirm the testing code does not autofill the verification field. Tests use mocked responses and the isolated in-memory test database; no real phone login was performed.

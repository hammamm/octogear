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
- iOS work and all Firebase work except the explicitly scoped Android first-time device-token capture are deferred for the current phase. Leave the existing Android Firebase configuration intact; do not add notification delivery, permission, token-refresh, or iOS Firebase behavior, and do not depend on Firebase for the foundation/session flow.
- The old iOS bundle identifier, display name, and `GoogleService-Info.plist` are intentionally untouched while iOS is deferred. They must be replaced together with the confirmed iOS bundle identifier and new Firebase configuration before any iOS build or release; never copy the old Sahala Firebase identity into OctoGear.
- The legacy Sahala Flutter scaffold has been removed: its GetIt wiring, old routes, sample features, old login/OTP code, widgets, extensions, legacy storage/messaging wrappers, old Poppins assets, and obsolete tests are not part of OctoGear. The root Dart package and project lint package are named `octogear` and `octogear_lints`.
- The external YARDY wireframes remain unchanged as a functional product reference. They must never be deleted as part of Flutter source cleanup.
- Android launcher, Android splash, and the shared Flutter header use the approved full-color original OctoGear mark in `assets/icons/app_icon.png` and `assets/icons/splash.png`. These are high-resolution source crops from page 4 of the supplied brand guide; preserve their proportions and colors. A raw designer-exported SVG/PNG may replace those files later only after visual review. iOS icon/splash generation remains deferred with the rest of iOS work.
- The two local OctoGear safety rules (`avoid_debug_print` and `avoid_direct_storage_imports`) continue to run through `custom_lint`. Its plugin protocol is deprecated upstream, so plan a deliberate migration to `analysis_server_plugin`; do not remove the rules merely to silence tooling output.
- The last verified Flutter test run passed 58 tests (2026-09-26). Run `flutter analyze` and `flutter test` after every material foundation or feature change.
- The customer root now uses a typed `StatefulShellRoute` with the semantic paths `/customer`, `/customer/stores`, `/customer/orders`, and `/customer/account`. Its tab bodies are intentionally static navigation previews until their bounded customer features are implemented; they make no API calls and must not be mistaken for completed discovery, order, or account features.

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

The local Laravel development server root is `http://127.0.0.1:8000`. The Flutter API base URL therefore resolves to `http://127.0.0.1:8000/api` because Laravel API routes live below `/api`.

Use `--dart-define` configuration rather than source edits when an environment is deployed:

| Environment | Temporary API value | Rule |
| --- | --- | --- |
| development | `http://127.0.0.1:8000/api` | Default for the current development setup. When Laravel is bound to the Windows loopback address, bridge LDPlayer/ADB with `adb reverse tcp:8000 tcp:8000`; use `http://10.0.2.2:8000/api` only when the host server is intentionally reachable from the emulator network. |
| test/staging | `https://api-staging.octogear.invalid/api` | Safe placeholder that must be replaced before deployment. |
| production | `https://api.octogear.invalid/api` | Safe placeholder that must be replaced with the real HTTPS production API. |

The `.invalid` hostnames deliberately fail rather than accidentally sending test or production traffic to an unknown server.

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

## Next feature implementation note: customer navigation shell

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

**API endpoint(s) and confirmed JSON example:** Protected `GET /customer/customer-cars`, using the standard envelope and the central bearer/locale headers. `data` is a newest-first, non-paginated list of objects containing `id`, `manufacturing_year`, legacy API key `vehicle_plat_number`, localized `car_name`, localized `color`, localized `fuel_type`, typed `pictures`, and `created_at`. Flutter maps the legacy transport spelling to the domain field `licensePlateNumber`; it must not rename the API in this slice. Each picture is controlled metadata with an exact API-relative owner-only stream URL, MIME type, size, and sort order—never a storage path, base64 value, or arbitrary host URL. Flutter rejects unexpected URLs before attaching a bearer header, renders an authenticated thumbnail for a valid first picture, and uses a neutral vehicle fallback when none can load.

**Loading/empty/error/offline states:** Render compact skeleton cards while loading, a truthful empty state when the returned list is empty, and a safe inline error with an explicit Retry action for no connection, timeout, server, permission, and unexpected failures. No failure clears a valid session. This safe `GET` may be manually refreshed; the feature explicitly disables Riverpod's default automatic retry and has no pagination because the API provides the customer’s complete personal saved-car list.

**Navigation inputs/result:** Account uses the generated `CustomerCarsRoute` helper to push the typed child route `/customer/account/cars`. The Back action returns to Account. My Cars pushes `CreateCustomerCarRoute` for the real `/customer/account/cars/add` child flow. A confirmed creation pops with `true`; the list then shows safe confirmation and refreshes from Laravel. The customer StatefulShell remains visible. Edit and delete remain later bounded slices; never add fake actions.

**Locale and RTL behavior:** All static copy is translated from the app translation files through `BuildContext`. The centralized `Accept-Language` header returns localized car, color, and fuel names. The controller observes the app locale so a visible list reloads with the selected language. License plates are explicitly rendered left-to-right.

**Analytics/notification behavior:** Deferred. No event, notification, or device-token behavior is introduced.

**Tests:** Cover the authenticated endpoint path/header and DTO mapping; private-media URL validation and same-origin bearer protection; controller success, empty, error/retry, and locale reload behavior; Account-to-My-Cars typed navigation; and screen loading, empty, error/retry, populated-card, image fallback, Arabic, and RTL states.

## Next feature implementation note: create customer car with private photos

**User action:** A signed-in customer opens **My cars**, selects **Add car**, chooses the vehicle information, optionally selects up to five gallery photos, and submits once.

**Roles/permissions:** Customer only. Laravel remains the authority for every operation through Sanctum authentication, active-user and customer middleware, and the `CustomerCarPolicy`. A customer may access only their own cars and their own photo bytes. A nested photo that belongs to another car must return `404`, not leak its existence.

**API endpoint(s) and confirmed JSON example:** The form reads localized, public reference data from `GET /reference/companies`, `GET /reference/companies/{company}/names`, `GET /reference/colors`, and `GET /reference/fuel-types`. Company is a selector helper only; the persisted request sends `car_name_id`, `manufacturing_year`, legacy key `vehicle_plat_number`, `color_id`, and legacy key `fuel_type`.

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

**Locale and RTL behavior:** All static copy is translated through `BuildContext`; reference names are localized by the API's shared `Accept-Language` header. Changing locale reloads reference lists without losing selected IDs where still available. Year and plate fields remain readable left-to-right inside Arabic UI. The image picker is gallery-only in this slice; Android lost-picker-data recovery is handled so an activity restart does not silently discard selected photos.

**Analytics/notification behavior:** Deferred. This slice adds no Firebase, notification permission, background upload, SMS, or external service behavior.

**Tests:** Laravel feature tests cover multipart creation, metadata/path secrecy, file validation, exact-payload idempotency/replay/conflict/expiry, retained-key purge scheduling, storage rollback cleanup, force-delete cleanup failure, owner-only streaming, nested-resource ownership, and localized errors. Flutter tests cover multipart fields/headers/files, typed picture decoding, private-media URL safety, references and dependent company/name selection, form validation/retained draft, photo limits/removal, loading/error/retry/idempotency behavior, successful list refresh, image fallback, accessibility, Arabic, and RTL.

## Next feature implementation note: customer-car detail, edit, and removal

**User action:** A signed-in customer taps one of their saved cars, reviews its full information and all private photos, then may edit vehicle details/manage photos or remove the saved car.

**Roles/permissions:** Customer only. Every endpoint remains protected by Sanctum, active-user/customer middleware, and the existing `CustomerCarPolicy`. A user may never inspect, update, remove, add a photo to, delete a photo from, or infer the existence of another customer's car or photo.

**API endpoint(s) and confirmed JSON example:** `GET /customer/customer-cars/{customerCar}` returns one owner-authorized car. Its resource includes localized top-level `company`, `car_name`, `color`, `fuel_type`, full ordered private-picture metadata, and the persisted scalar values. `PATCH /customer/customer-cars/{customerCar}` receives only scalar JSON fields (`car_name_id`, `manufacturing_year`, legacy `vehicle_plat_number`, `color_id`, and legacy `fuel_type`); the Flutter domain names stay clear even while those existing transport keys remain unchanged. Photo mutation deliberately stays separate: `POST /customer/customer-cars/{customerCar}/pictures` sends multipart `pictures[]`, and `DELETE /customer/customer-cars/{customerCar}/pictures/{customerCarPicture}` removes one owner-authorized photo. `DELETE /customer/customer-cars/{customerCar}` soft-removes the saved car from customer lists. It is not presented as permanent deletion because private-media retention/purge policy is a separate operational requirement.

**Loading/empty/error/offline states:** The detail screen has explicit loading, not-found, permission, retryable network/server error, and successful states. It fetches a fresh detail resource instead of trusting the list card as a full record. Edit retains unsaved scalar changes and local photo choices on validation/network/server failure. Scalar save and each photo action are explicit, disabled while in flight, and report their own safe result; do not make one opaque multipart PATCH. Car removal requires a clear destructive confirmation and never happens automatically. A `404` after a stale card returns to My Cars with a truthful message; a timeout/5xx preserves the screen and offers Retry.

**Navigation inputs/result:** A list card pushes the typed child route `/customer/account/cars/:carId`; it passes only the numeric identifier. Detail can push a typed edit child route. A successful edit/photo change pops back to detail with refreshed server data. A confirmed removal pops to My Cars with `true`, and the list explicitly reloads. Do not pass a token, photo bytes, file paths, or mutable car object through a route.

**Locale and RTL behavior:** Static copy uses `BuildContext` translations. API names/localized company follow the shared `Accept-Language` header. The detail view refreshes locale-dependent data when the language changes. Plate values and manufacturing years remain left-to-right. Photos use only the existing authenticated same-origin image component; no raw storage path or bearer token enters a URL.

**Analytics/notification behavior:** Deferred. This slice adds no Firebase work, background upload, or notification behavior.

**Tests:** Laravel covers localized company, active-reference validation, owner detail/update/delete/photo authorization, missing/stale resources, and soft removal. Flutter covers typed DTO/repository mapping, route/card tap, detail loading/error/photo gallery, edit validation/save/photo mutation, destructive removal confirmation, list refresh, private image fallback, and Arabic RTL behavior.

### Customer-car media deployment and deletion safety

Before deploying this feature, run Laravel migrations, configure the production scheduler to invoke `php artisan schedule:run` every minute, and verify that the hourly customer-car idempotency cleanup command appears in `php artisan schedule:list`. Set PHP and reverse-proxy multipart size limits at or above the API's 5 MiB-per-image contract. Configure and test a GD/Imagick-capable normalization/EXIF-removal worker or approved image service before public production use; client compression is only a usability optimization, not a privacy control.

The legacy migration deliberately hides old raw picture values rather than guessing that their files are trustworthy. Before deploying against existing production data, take a backup and explicitly choose a tested private-media backfill or a customer-visible retirement path. Do not roll back the media migration after new private uploads exist. Eloquent `forceDelete()` cleans a car's private media first and aborts safely if storage cleanup fails. Any future account deletion, raw database maintenance, bulk deletion, or database-cascade path must first use an explicit media-purge lifecycle; never assume a database cascade removes private files.

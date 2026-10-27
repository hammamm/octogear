# Access and refresh sessions — 2026-10-23

User action: Sign in normally, use the app for up to 14 days, then sign in again.
Roles: Existing customer/provider authorization and profile validation remain.
API: OTP verification and registration now return token, refresh_token,
session_id, expires_in (600), access_expires_at and session_expires_at.
POST auth/refresh accepts {refresh_token, request_id: UUID}; it rotates both
credentials without extending the original 14-day deadline. POST
auth/session/logout revokes the family using its refresh token, even after access
expiry. See ../OctoGear-api/AUTH_SESSIONS.md for the server contract.

Store the pair, API origin, deadlines and any pending refresh request UUID as one
secure-storage record. Never store credentials in preferences. Serialize writes,
coalesce refreshes, and preserve the request UUID across uncertain failures.
Renew before protected requests and retry a rejected read once. Never replay
writes automatically. Confirmed invalid refresh clears the login; offline/5xx
retains credentials and existing explicit Retry states. Legacy access-only
sessions remain usable until their server-enforced expiry, then require sign-in.

Session identity stays stable through rotation, preserving chat, push, drafts,
language saves and stale-response guards. Logout clears local state even offline;
remote revocation cannot be guaranteed without a successful server response.
Private images also obtain fresh bearer headers before fetching. No credentials
in navigation, logs or analytics. No new visible strings or RTL changes.

Verification: add transport, rotation/replay, persistence, concurrency, expiry,
logout/race and environment-isolation tests; run analyze, custom lint and full
Flutter tests. Backend migration must precede updated clients. Historical
no-refresh instructions are superseded by this explicitly approved contract.

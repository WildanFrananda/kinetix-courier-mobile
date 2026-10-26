# CLAUDE.md — Enterprise Flutter Architecture

These instructions MUST be followed by the AI assistant (Claude) when interacting with this project or generating new Flutter code.

## 1. Context & Architecture Goal

This project uses a **custom Enterprise Flutter Architecture**, optimized for Mobile (iOS/Android) and focused on:

- Strict **Type-Safety**
- **Separation of Concerns (SoC)**
- Minimizing boilerplate

### Core Paradigms

| Aspect | Choice |
|---|---|
| Navigation | Mobile-first Declarative Navigator 2.0 (`Navigator(pages: [...])`) — **NOT** `MaterialApp.router` or `go_router` |
| Routing Definition | Dart 3 `sealed classes` for 100% type-safe route definitions |
| Architecture Pattern | MVVM (Model-View-ViewModel) |
| Dependency Injection | `get_it` + `injectable` |
| State Management (UI/ViewModel) | `provider` (`context.watch` / `context.read`) |
| State Management (Navigation) | Centralized `ChangeNotifier` (`AppRouterState`) acting as a Singleton router |
| Data Modeling | `freezed` for immutable, type-safe data classes |
| Data Access | `Repository` per aggregate, sitting over `Service`s — **NO UseCase / Interactor layer** |
| Cross-cutting reuse | `mixin`s for shared behavior, `extension`s for ergonomic helpers (see §5) |

### Layered flow

```
UI (StatelessWidget)
  └─ watch ─▶ ViewModel (ChangeNotifier, @injectable)
                 └─ calls ─▶ Repository (@injectable)      ◀── domain-typed boundary
                                └─ uses ─▶ Service (@injectable)  ◀── raw I/O (WS, REST, storage, GPS)
```

A ViewModel talks to **Repositories** for domain data and to **Services** only for
imperative, non-data concerns (e.g. starting the GPS stream). There is **no
UseCase layer**: any orchestration a UseCase would hold lives in the Repository
(if it is data-shaped) or the ViewModel (if it is view-shaped).

## 2. Required Packages

Ensure the following packages are included in `pubspec.yaml` when setting up or updating the project:

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.2              # UI State Management
  get_it: ^7.7.0                # Service Locator
  injectable: ^2.4.1            # DI Code Generator
  freezed_annotation: ^2.4.1    # Model Code Generator

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.9           # Task runner for code generation
  injectable_generator: ^2.6.1   # Generates DI config
  freezed: ^2.5.2                 # Generates immutable classes
```

> **Note:** Always use the latest stable versions compatible with the current Dart SDK.

## 3. Strict Coding Rules & Workflows

When asked to generate new features, screens, or logic, follow this sequence and structural rules.

### Rule 1 — Data Models (`lib/models/`)

- Always use `@freezed` for data models.
- Never use standard mutable classes for data entities.

### Rule 2 — Routing (`lib/routes/`)

- **NEVER** use string-based routing (`Navigator.pushNamed`).
- **NEVER** use `Navigator.of(context).push(...)` inside UI files.
- When adding a new screen, first define its route as a subclass of the `sealed class AppRoute` in `app_route.dart`.
- Pass required arguments directly into the route's sealed class constructor (e.g., `DetailRoute({required this.product})`).

### Rule 3 — ViewModels (`lib/viewmodels/`)

- ViewModels must extend `ChangeNotifier`.
- ViewModels must be decorated with `@injectable`.
- ViewModels must inject `AppRouterState` via their constructor if they need to navigate.
- ViewModels must not depend on `BuildContext`. Navigation intent is sent to `AppRouterState` (e.g., `_router.push(NewRoute())`).
- ViewModels get **domain data from Repositories** (constructor-injected), never by
  touching a data source, `dio`/`http`, storage, or `dynamic` JSON directly.
- ViewModels may inject a **Service** directly only for non-data actions
  (e.g. `LocationService.start()`); anything that reads/writes domain models
  goes through a Repository.

### Rule 4 — UI Screens (`lib/ui/screens/`)

- Screens should generally be `StatelessWidget`.
- Use `context.watch<YourViewModel>()` to rebuild the UI based on state changes.
- UI actions (button clicks) must only call methods on the ViewModel (e.g., `onPressed: () => viewModel.submit()`).
- The UI must have zero routing logic.

### Rule 5 — Route Mapper (`lib/routes/app_route_mapper.dart`)

- When a new route and screen are created, you MUST update the `AppRouteMapper.toPage()` switch statement.
- If the screen requires a ViewModel, use the functional injection helper: `child: _inject<YourViewModel>(const YourScreen())`.
- Do NOT clutter `main.dart` with Providers. `main.dart` should only initialize DI and provide the global `AppRouterState`.

### Rule 6 — Repositories (`lib/repositories/`)

The Repository is the **domain-typed boundary**. It is where raw payloads become
`freezed` models and where the app's data operations live. **There is no UseCase
layer** — do not create one.

- One Repository per aggregate/feature, e.g. `OrderRepository`, `SessionRepository`.
- **Always define the contract as a Dart 3 `abstract interface class`**, and put the
  implementation in a separate `<Name>Impl` class. ViewModels depend on the
  interface only — never on the `Impl`. This is mandatory, not optional.
  ```dart
  // lib/repositories/order_repository.dart
  abstract interface class OrderRepository {
    Stream<Order?> watchActiveOrder();
    Future<void> pickup(int orderId);
    Future<void> delivered(int orderId);
  }

  // lib/repositories/order_repository_impl.dart
  @LazySingleton(as: OrderRepository)
  class OrderRepositoryImpl implements OrderRepository { /* uses ChannelClient */ }
  ```
- Bind the impl with `@LazySingleton(as: XRepository)` (or `@Injectable(as: XRepository)`
  for stateless). The interface stays annotation-free; only the `Impl` is annotated.
- Depend on **Services**, never the other way around. A Repository may combine
  several Services (e.g. `SessionRepository` = `AuthService` + `TokenStore`).
- Expose **only domain types**: `freezed` models, enums, `Stream<Order>`,
  `Future<DriverSession>`. **Never** leak a `Map<String, dynamic>`,
  `ChannelEvent`, `http.Response`, or any transport/storage type to a ViewModel.
- All JSON parsing (`Model.fromJson`) happens **here**, at this boundary — not in
  ViewModels, not in Services.
- The `abstract interface class` gives a clean seam: tests inject a fake
  implementing the interface, no mock of the concrete `Impl` needed.

### Rule 7 — Services (`lib/services/`)

Services own **raw I/O and protocol**, not domain logic.

- Examples: `ChannelClient` (WebSocket/Phoenix protocol), `LocationService`
  (`geolocator`), `TokenStore` (`flutter_secure_storage`), an HTTP `AuthService`.
- Decorate with `@lazySingleton` / `@injectable`; close every sink/subscription
  (a `@disposeMethod` that closes controllers satisfies the strict lints).
- Services may return raw shapes (`Map`, `ChannelEvent`, `Position`); it is the
  **Repository's** job to map those into domain models. A Service must not import
  `viewmodels/` or `routes/`.

## 4. Type-Safe Patterns (mandatory)

Six patterns keep ViewModels thin and make illegal states uncompilable. Apply them
by default; do not fall back to bool flags, `dynamic`, or thrown errors at the UI.

Folders: `lib/core/` (Result, Failure), `lib/state/` (sealed UI states & domain events).

### 4.1 `Result<T>` — no throwing across the repo boundary

- Repositories return `Future<Result<T>>` / typed `Stream`s; they **never** throw to a
  ViewModel. `Result<T>` is sealed `Ok<T>` | `Err<T>` (`lib/core/result.dart`).
  Void success uses the `Unit` sentinel.
- `try/catch` is allowed **only inside a Repository impl** — that is where a Service/SDK
  throw is converted into `Err(Failure)`. **Never** write `try/catch` in a ViewModel or
  UI. `main.dart` may keep a single `runZonedGuarded` crash safety net.
- ViewModels consume a `Result` with `.fold(onOk, onErr)` or a `switch`.

### 4.2 Sealed ViewModel UI state — no scattered flags

- Each screen's ViewModel exposes **one** `sealed` state object (in `lib/state/`), not a
  bag of `bool _isLoading` / `String _error` fields. Loose input buffers (text fields)
  may stay as plain fields; anything the UI branches on lives in the sealed state.
- The screen renders it with an **exhaustive `switch`**. Impossible combinations become
  uncompilable; a new state forces every screen to handle it.

### 4.3 Sealed `Failure` hierarchy

- Domain errors are a sealed `Failure` (`lib/core/failure.dart`): e.g. `NetworkFailure`,
  `AuthFailure` (token expired → route to login), `ChannelFailure(reason)`,
  `TimeoutFailure`. Repositories map raw reasons/exceptions into these.
- ViewModels branch on the **type** (`if (f is AuthFailure)`), never on a raw string.

### 4.4 Sealed domain events — parse transport at the boundary

- Services emit raw shapes (`ChannelEvent`, `Map`); the **Repository** maps them to a
  sealed domain event (e.g. `ServerEvent` in `lib/state/`) and/or a `freezed` model.
- No `fromJson` and no event-name string matching inside a ViewModel (reinforces Rule 6).

### 4.5 Extension-type IDs — no bare `int` identifiers

- Domain identifiers use zero-cost `extension type const XId(int value)`
  (`lib/models/ids.dart`), e.g. `OrderId`, `DriverId`. This makes `pickup(driverId)`
  where an `OrderId` is expected a compile error.
- Provide one `JsonConverter` per id (`lib/models/converters.dart`) so
  `freezed`/`json_serializable` map it. Services may still take raw `int`; convert with
  `.value` at the Service call. Read `.value` when displaying.

### 4.6 Barrel files

- Each layer folder may expose a barrel (`models/models.dart`, `core/core.dart`,
  `state/state.dart`) for one-line imports. Keep barrels flat (no cross-layer re-exports)
  to avoid import cycles.

## 5. Mixins & Extensions

Use these for cross-cutting reuse instead of inheritance or helper "util" god-classes.

### Mixins (`lib/mixins/`)

- Use a `mixin` for behavior shared across ViewModels/Services that is **not** an
  is-a relationship — e.g. `DisposeBagMixin` (track & cancel subscriptions),
  `RetryMixin` (retry-until-ack for lifecycle actions, PRD §7.2).
- Name them `<Behavior>Mixin`. Constrain with `on` when they need a base type,
  e.g. `mixin RetryMixin on ChangeNotifier`.
- A mixin must be self-contained: no hidden dependency on fields it does not declare.

### Extensions (`lib/extensions/`)

- Use an `extension` for ergonomic, **stateless** helpers on existing types —
  e.g. `extension IsoDateTime on DateTime { String toIso8601Utc() => ... }`,
  `extension OrderStatusX on OrderStatus { bool get isActionable => ... }`.
- One file per extended type (`date_time_extensions.dart`, `order_status_extensions.dart`).
- Name the extension `<Type>X` or a descriptive name; always give it an explicit
  name (no anonymous extensions) so it can be shown/hidden on import.
- Extensions must not hold state or perform I/O. Pure functions only.

## 6. Example: Feature Addition Workflow

If the user asks: *"Create a Profile screen where a user can edit their name"*, the response must include:

1. **Model** — (if needed) e.g., a `UserProfile` freezed class.
2. **Repository** — define `abstract interface class ProfileRepository` + a
   `@LazySingleton(as: ProfileRepository) class ProfileRepositoryImpl` that does the
   JSON↔model mapping over a Service. (Skip only if the feature reads no domain data.)
3. **AppRoute Update** — add `class ProfileRoute extends AppRoute {}`.
4. **ViewModel** — create `ProfileViewModel` (`@injectable`, extends `ChangeNotifier`,
   takes `AppRouterState` and `ProfileRepository` — the interface, not the impl).
5. **UI Screen** — create `ProfileScreen` (Stateless, reads VM via `context.watch`).
6. **Mapper Update** — add `ProfileRoute() => MaterialPage(child: _inject<ProfileViewModel>(const ProfileScreen()))` to the switch statement in `app_route_mapper.dart`.

## 7. Decisions the code states but cannot explain

### A refused session is renewed once, then matching is asked why

Identity's access token lives fifteen minutes and its refresh token thirty days. `SessionRenewer` trades the
refresh token for a new pair and stores both before anything uses them. It sends one request at a time for the
whole app, because identity treats a refresh token presented twice as stolen and revokes the family. `TokenStore`
keeps the session as one secure-storage record written in one call, so a crash can never keep half of a rotated
pair (identity would read the old refresh token as reuse).

What a refresh answer means:
- `400`, `401` or `403`: refused; the session is cleared and the courier signs in again. Identity has no account
  suspension at sign-in or refresh (2026-10-22); a deactivated courier is refused by matching
  (`pending_approval`). A `403` used to be retried forever as an outage. `401 CLIENT_MISMATCH` (the session was
  started by another client name) is one of these: identity spent nothing, but no retry or fresh proof changes
  the name, so it is sent once and the session ends.
- `400 UNKNOWN_CLIENT` or `CLIENT_REQUIRED`: identity does not accept this build. Its guard refuses before the
  token is read, so the refresh token is unspent and the session is kept for an updated app;
  `AppUpdateRequiredFailure` ends the socket's recovery as `SessionUpdateRequired` (see "The app proves itself
  to identity").
- `429`, `502`, `503`, a request that never left the phone (no connection, connect or send timeout, TLS) or no
  App Check token on the phone: identity did not decide; the session is kept and renewed later.
- An answer lost after the request was sent (receive timeout, the connection dropped mid-answer, `500`, `504`)
  or a `2xx` this app cannot read: identity may have spent the refresh token. Presenting it again would be read
  as theft and revoke the family, so the session is cleared and the courier signs in again.

Matching refuses a driver socket at the HTTP upgrade, `403` with no body, for an expired token, a token whose role
is not `courier`, an account with no vehicle and a courier who is pending or deactivated alike; `503` means it could
not ask identity. `ConnectionRepositoryImpl` answers a refusal by renewing and reconnecting. A second refusal
before a connection has held is real, and the app asks `GET /api/v1/matching/driver/me` what it is:
`403 pending_approval` ends the session as `SessionNotApproved` (the waiting screen, session kept, so an approved
courier carries on at the next start); `401`, another `403` or `404` ends it as `SessionSignedOut`; a profile
whose `id` is not the stored driver rebinds the session to that driver and rejoins at once; no answer is retried
after 1, 2, 4 … up to 30 seconds, and at once when the app returns to the foreground. A join refused with
`pending_approval` is `SessionNotApproved` at once. Splash asks the same question before it opens the socket, so a
courier who registered and is still waiting never reaches the tracking screen. Every `standing()` writes the
driver `driver/me` names over the stored one (a stale id used to reconnect every 30 s forever), and the waiting
screen's "Check again" asks it on demand.

### Signing in keeps a pending session and revokes every other

After login or `2fa/verify`, `driver/me` decides. `200` stores the session with that driver. `403
pending_approval` stores it without a driver (`DriverSession.driverId` is null): the fleet names the driver only
once it approves, and the next `standing()` fills it in; `ChannelClient` never opens a socket for a session
without a driver and answers `notApproved`, so such a session can only reach the waiting screen. Any other answer
(`404`, `401`/`403`, `5xx`, no answer, an unreadable body) sends the fresh pair to `POST /api/v1/auth/logout`
within five seconds and stores nothing, so no thirty-day refresh token is left alive and forgotten. A `2xx` this
app cannot read is `UnreadableAnswerFailure`, never `NetworkFailure`: after `2fa/verify` the challenge is spent, so
the courier signs in again; after registration the account exists, so the courier signs in with the same email.

### Identity's sign-in delay is waited out, never argued with

Identity counts attempts per account (`sign_in_attempt_policy.ts`): from the fifth the next waits 1, 2, 4 … up to
60 s. A request inside the wait is `429 SIGN_IN_DELAYED`, with `retryAfterSeconds` in the body and `Retry-After`,
answered before any password or code is read and not counted, on login, `2fa/verify` and a courier registration
that resumes an account. `IdentityError.delayOf` reads the body's seconds, else `Retry-After` (also what the
per-address throttle sends), and the repository answers `SignInDelayedFailure(wait)`. `SignInDelayMixin` keeps the
moment the wait ends, ticks once a second, shows "Try again in N seconds" as the error and holds the submit
(`delayed`) until then; the login and registration view models refuse to send while it runs, so a courier cannot
spend the next attempt early. It is never a wrong password: the code step keeps its challenge, which identity did
not count either, and no stored session is touched. A `429` that names no wait keeps the old "wait a minute".

### A challenge takes five codes, and only one answer keeps it

Identity's challenge allows five attempts (`two_factor_challenge_attempts`); the sixth is refused even with the right
code, and a new challenge needs the password. It answers every refusal of `2fa/verify` with 401 and Nest's default
body (`{"statusCode": 401, "message": …, "error": "Unauthorized"}`), no code of its own, so the app reads the
message. Exactly `That code is not valid` (`IdentityError.wrongCodeMessage`) keeps the code step; every other 401
from verify (`This challenge allows no more attempts; sign in again`, a code already used, a challenge already
answered, an expired or foreign token, an account gone) means the challenge can take no more codes and is
`ChallengeSpentFailure`: the courier is back at the password with the reason. If identity rewords the wrong-code
message, a wrong code sends the courier back to the password, the safe side; a code in identity's body would end
the string match.

### An administrator is not a courier

An admin without a second factor who signs in correctly gets `{mfaEnrolmentRequired, enrolmentToken, …}` instead of
a session. The courier app does not enrol admins: `login` answers `AdminAccountFailure` ("this app is for
couriers"), stores nothing and asks the fleet nothing. The enrolment token is dropped, not revoked: it lives 600 s
with no refresh token, and identity refuses it on logout (`403 TWO_FACTOR_ENROLMENT_ONLY`). The app has no call to
`2fa/setup`, `2fa/enable` or `2fa/disable`, so identity's rule that they need the account password
(`PASSWORD_REQUIRED`) does not reach it.

### The socket is Kong's route, and its token is a subprotocol

The URL is `<WS_BASE>/ws/v1/matching/driver?vsn=2.0.0`. Kong's route strips `/ws/v1/matching/driver` and sends
the rest after the service path `/driver/websocket`, which is Phoenix's socket; `/ws/v1/matching/driver/websocket`
reaches `/driver/websocket/websocket` and Phoenix answers 404 (production, 2026-10-21). The access token is not in
the URL, which Kong's access log records: it is offered in `Sec-WebSocket-Protocol` as
`base64url.bearer.phx.<the token, standard base64, padding removed>` beside `phoenix`. Despite the prefix, Phoenix
decodes it with `Base.decode64!(…, padding: false)`, the standard alphabet; a JWT encodes to the same characters
in both.

A heartbeat goes every 30 s and its reply must come within 10 s; a push that times out (5 s) sends a heartbeat at
once. Phoenix answers heartbeats from the socket process, not from the channel, so a missing reply means the
connection is dead (half-open after a cell handover), not that a handler is slow; the socket is torn down and
reconnected, and the next join declares duty again. Before, replies were dropped and the courier stayed off duty
at matching without knowing it.

`WsChannelSocket` connects with `IOWebSocketChannel.connect`, not `WebSocketChannel.connect`: the latter goes
through `package:web_socket` 1.0.1, which rethrows dart:io's `WebSocketException` without its `httpStatusCode`, so a
refusal looked exactly like an outage and a pending courier reconnected forever. `401`/`403` at the upgrade is a
refusal; every other status, and an address nothing answers, is retried. `socket_handshake_test.dart` proves both
against a real local server.

### Duty is declared after every join

Joining `driver:<id>` puts nobody on duty; the join reply carries the status matching holds. While the courier is
on duty the app sends `status online` after every join (a disconnect took it off duty) and, once that succeeds,
one `ping` at once with the newest fix, moved or not, because matching dispatches only on a position received
after the courier went on duty. A courier off duty whose join finds it online is set `offline`. The `status` reply
is what matching decided (`online` is `busy` while the courier carries a job), and that is what the screen shows.
A `status` whose reply was lost is asked again on the next four-second tick. `recorded_at` is the fix's own time,
never the send time.

### Positions recorded offline go as `ping_batch`, never as `ping`

Matching keeps one live position per courier, the newest by `recorded_at`, and ignores an older `ping`; so a fix
that could not go live never goes through `ping` later. A fix is kept in the Hive box `offline_positions`
(`OfflinePositionStore`, a lazy box whose key ends in the fix's microseconds since the epoch, so one moment is one
entry per courier and the keys sort oldest first) whenever it cannot be sent live: no socket, joined but `status online` not yet
answered, a `ping` whose push failed or timed out, or a fix taken during a `rate_limited` pause. The five-metre
filter applies to kept fixes as to live ones; when a pause ends the newest fix goes live once, moved or not.

Positions belong to a courier. The key is `<driver id>:<microseconds, 17 digits>`, the courier being the one who
went on duty (`DutyRepositoryImpl._owner`); a batch is read and removed only for the driver of the socket
(`ChannelClient.driverId`), and `ChannelClient.pingBatch` refuses a batch whose owner is not the socket's driver.
Courier A's unsent positions therefore wait for A's next sign-in on that phone and never go out as courier B's
history (they did before: the box had no owner). Entries kept by an older build, without an owner, are deleted
when the box opens. Capacity and the 24-hour cut apply to the whole box.

The queue is sent with `ping_batch` (`{"pings": [ping fields, ...]}`), which matching stores as history and never
as the live position. It starts after the join, `status online` and the fresh live fix (or right after a join while
off duty, when there is no live position to put first), oldest first, at most 100 positions per batch, one batch
in flight and one timer at most: a live ping that succeeds while a batch is pending or a retry is scheduled starts
nothing. An `ok` reply settles the whole batch, `refused` entries included, and only then is the batch deleted.
Each refusal is a verdict on the entry itself, which no resend changes: `too_old` only grows older,
`invalid_telemetry` is its content, and `ahead_of_server_clock` means its time came from a clock matching does not
trust, so waiting would store a wrong time as history. They are logged with their counts, and
`ahead_of_server_clock` tells the courier to set the clock automatically. An
error reply (`unavailable`, `invalid_batch`, `batch_too_large`) or no reply keeps it and retries after 5 s,
doubling up to 5 min; `rate_limited` waits the 60 s window, because matching allows 30 batches a minute (apart
from the live pings' 100 per 10 s) and says nothing about when to come back. Batches that succeed go 2.5 s apart,
24 a minute. A disconnect cancels the scheduled batch; the next join starts again. Positions older than 24 hours
are deleted before each batch rather than sent, because matching refuses them as `too_old`.

The box holds at most 21,600 positions, the oldest dropped first: a day of driving at the four-second cadence,
which is everything matching would still accept. A lazy box keeps only its keys in memory and reads positions
from disk when a batch is made, so a full box costs a few megabytes of memory and of disk, and it drains in about
nine minutes at 24 batches a minute.

`rate_limited` on a live ping pauses live pings for ten seconds; `invalid_telemetry` (a phone clock more than five
minutes ahead) is shown to the courier and that fix is not sent again.

### Background tracking is geolocator's foreground service

On Android the position stream is started with `ForegroundNotificationConfig`, so geolocator's own location
foreground service runs exactly while the courier is on duty and stops with the stream, or with the process.
`flutter_foreground_task` was removed: its task handler was empty, the app's work never ran in it, and its
service outlived the Flutter engine with a notification saying the location was shared while nothing was sent. On
iOS `UIBackgroundModes` `location` sits at the top level of `Info.plist` (it was inside the scene manifest, where
iOS does not read it) and the stream allows background updates.

### Signing out reaches identity first

`SessionRepository.logout` calls `POST /api/v1/auth/logout` with the access token and the refresh token, so the
refresh family ends at identity; an expired access token is renewed once for it. If identity cannot be reached
within five seconds the courier is signed out on the phone anyway, and that refresh token stays valid at identity
until it expires: the courier's choice to sign out wins over an unreachable server. Enabling or disabling a second
factor elsewhere ends this session; the next renewal is refused and the courier is signed out like any refusal.

### The build names the edge

`HTTP_BASE` and `WS_BASE` have no defaults. They come from `--dart-define-from-file=dart_defines/<environment>.json`
(`bin/build` passes it), must be `https://` and `wss://` with no path, and an app built without them shows what is
missing instead of starting. The Android manifest allows no cleartext. The same check covers the Firebase values
and `APP_CHECK_PROVIDER` (next section). `bin/build lab` makes a debug build and `bin/build production` a release
build.

### The app proves itself to identity

Login, `2fa/verify`, courier registration and refresh carry `X-Kinetix-Client: courier-app` (a public name,
`@Headers` on `DriverApi`) and `X-Firebase-AppCheck: <App Check token>`; logout and `driver/me` carry neither.
`ClientProof.present` takes the SDK's cached token; on `401 CLIENT_PROOF_REQUIRED` or `CLIENT_PROOF_INVALID` (the
code is the JSON body's `error`) it asks for a fresh one and retries once. A second refusal is
`UntrustedClientFailure`, never "wrong password"; on refresh it ends the session, because retrying would spend the
Play Integrity quota (10,000 a day) on a phone identity will not accept. `503 CLIENT_PROOF_UNAVAILABLE`, and a
phone that cannot get a token at all, are "try again later" and never sign anyone out.

`400 UNKNOWN_CLIENT` and `CLIENT_REQUIRED` mean identity does not know this app's name (its `IDENTITY_CLIENTS`
lacks `courier-app`, or the name was retired) or never received it (something on the way dropped the header):
nothing this phone can do fixes it. They are `AppUpdateRequiredFailure`, never a credentials error, and every place
that meets one (sign-in, the code, registration, the splash, the waiting screen, a renewal behind the socket)
replaces the stack with `UpdateRequiredRoute`, which asks for no credentials. Nothing retries it; "Try again"
starts again from the splash. A stored session is kept, so an updated app carries on without signing in.

Firebase is started from dart-defines, not from `google-services.json` or `GoogleService-Info.plist`, and the
Google services Gradle plugin is not used: `FIREBASE_PROJECT_ID`, `FIREBASE_MESSAGING_SENDER_ID`,
`FIREBASE_API_KEY_ANDROID`, `FIREBASE_APP_ID_ANDROID`, `FIREBASE_API_KEY_IOS`, `FIREBASE_APP_ID_IOS` (each platform's
app has its own key and id). `FIREBASE_MESSAGING_SENDER_ID` must be the project number: the Play Integrity
provider passes it to Play as the Cloud project number, and identity checks the same number in the token's `iss`
and `aud` (`FIREBASE_PROJECT_NUMBER` there). The keys are in both define files with empty values until the user
fills them; an empty one keeps the app on its error screen. `firebase_app_check` ships the Play Integrity and
debug providers, so Android needs nothing more.

`APP_CHECK_PROVIDER` is `attestation` (Play Integrity, App Attest) in production and `debug` in the lab. A release
build never uses the debug provider: `AppConfigCheck` refuses to start with `debug` when `kReleaseMode`, and
`AppCheckActivation.providersFor` returns the attested providers whenever `releaseBuild` is true. The debug
provider prints its token in logcat or the Xcode console; it is registered in the Firebase console per lab device
and never written into a define file. The lab needs the same Firebase values: the debug provider trades that
token with Firebase for a real App Check token, which identity verifies like any other. iOS needs 15.0 (Firebase's packages) and `Runner.entitlements` with
`com.apple.developer.devicecheck.appattest-environment` `production`.

What the user does once (consoles):
- Firebase: register the Android app (package name, SHA-256 of the app signing key from Play Console → App
  integrity → App signing, and of the upload key) and the iOS app (bundle id, team id); copy each app's API key
  and app id, the project id and the project number into `dart_defines/production.json` and `lab.json`.
- App Check: register Play Integrity for the Android app, requiring device integrity (`MEETS_DEVICE_INTEGRITY`,
  so rooted phones and emulators are refused), and App Attest for the iOS app; token time to live 1 hour; add
  each lab device's debug token. The console's enforcement switches cover Firebase products only; identity
  enforces App Check for Kinetix.
- Play Console: link the Firebase project's Cloud project (App integrity → Play Integrity API). Play Integrity
  recognises only an app installed through Google Play: an internal testing track is enough, a sideloaded APK
  always fails.
- Apple: enable App Attest on the App ID, so automatic signing puts it in the provisioning profile.
- The ids are still `com.example.fleet_pulse_mobile` and `com.example.fleetPulseMobile`, and release builds are
  signed with the debug key: Play refuses `com.example`, so both must be chosen before the apps are registered.

`dio` exports a `Headers` class too, so `driver_api.dart` imports it with `hide Headers`; without that, Retrofit's
generator cannot resolve `@Headers` and the whole DI container fails to build.

### Proof of delivery

`delivered` needs the photo URL and the signature (`signature_required` without it). The camera photo is taken at
most 1920 px on a side at JPEG quality 85, so it stays far below the gateway's 16 MB storage limit, and is refused
before it is hashed unless its first bytes are a JPEG's, which matching checks too. A `pickup` or `delivered` whose
reply was lost is retried until answered (1, 2, 4 … 15 s), as long as the courier's session holds the socket
(`ChannelClient.driverId`); matching answers the repeat `ok`, so the courier sees success. A push timeout is
`TimeoutFailure`. `proof_unverifiable` is retried as well. It used to stop after about 30 s.

The uploaded photo's URL and the signature are kept in the Hive box `delivery_proof_drafts`, keyed by driver and
job, until the delivery is answered, the job is cancelled, taken off the courier or no longer active, or 24 hours
pass; a job screen opened again (after the app was killed) restores them.

### A job screen changes only for news about its own job

`OrderRepository.watchJobs` maps channel events to `JobUpdate`: `JobActive(order)`, `JobNone` (`active_order`
null), `JobCancelled(id)`, `JobUnassigned(id)` (also an `order_updated` whose job is pending again). An event this
app cannot read emits nothing. `active_order` names the newest of possibly several active jobs, so a job screen
ignores news about another job; only `JobNone` says its job is no longer active ("This job is no longer active
for you", not "Order cancelled", which both used to show).

### A repository the container disposes declares `dispose`

`injectable` types the dispose callback by the registered interface, so `ConnectionRepository` and
`DutyRepository` declare `dispose()`. At `ed533f7` `ConnectionRepository` did not, and the generated container,
which neither `flutter analyze` (it skips `*.config.dart`) nor the unit tests compiled, broke every build of the
app. `test/di/injection_test.dart` builds the container in the unit suite.

# Product Requirement Document (PRD): FleetPulse Driver App

**The courier-facing mobile client of the Kinetix fleet (`kinetix-matching-service`), signed in by
`kinetix-identity-service`, reached only through the edge (`kinetix-api-gateway`).**

---

## 1. Executive Summary

FleetPulse Driver turns a courier's phone into a live position source and a job terminal: it streams GPS to
matching over a persistent WebSocket, receives dispatched jobs in real time, and lets the courier carry a job
through pickup and a proved delivery, while surviving the flaky connectivity of real-world driving.

The services hold every business rule. This app is a **thin, resilient client**: it owns connectivity, location,
battery discipline and a clean courier UX, and decides nothing the services decide.

---

## 2. Problem Statement

A courier on the road needs an app that stays connected through tunnels and cell handovers, reports its position
without draining the battery, and shows the current job with unambiguous pickup and deliver actions. Dispatch
needs every courier's position to be fresh, and every delivery to carry evidence: a photo of the parcel and the
receiver's signature.

---

## 3. Goals & Non-Goals

### Goals (V1)

- Register a courier and its vehicle in the app; the account waits for an administrator's approval.
- Sign in with email and password, and a TOTP code when the account has a second factor.
- Hold the session securely and renew it without asking the courier to sign in again.
- Keep a live WebSocket to matching's driver channel, with automatic reconnection.
- Let the courier go on and off duty; while on duty, stream the position every few seconds, including with the
  screen off.
- Receive dispatched jobs at once; show pickup and drop-off.
- Mark a job **picked up**, then **delivered** with a photo and a signature.
- Degrade gracefully offline and recover cleanly on reconnect.

### Non-Goals (V1)

- Turn-by-turn navigation (the phone's map app opens through a deep link).
- Chat, ratings, earnings or payments in the app.
- Enabling or disabling the second factor (done elsewhere; the app honours it).
- The dispatcher's tools (matching's backoffice API).

---

## 4. Target User

A **courier** driving a vehicle, using their own Android or iOS phone, often with one hand, in bright sunlight, on
intermittent mobile data. Primary needs: know whether they are connected and on duty, know their next job, and
complete it in as few taps as possible.

---

## 5. Service Contract (source of truth)

The app speaks these contracts exactly. Every request goes to the edge (`HTTP_BASE`, `WS_BASE`), TLS only.

### 5.1 Registration — identity

```
POST /api/v1/couriers/register
  request: { "email", "password", "fullName", "phoneNumber", "vehiclePlate", "capacityKg" }
  201:     { "accessToken", "refreshToken", "expiresIn", "tokenType", "user": {…}, "driverId" }
```

- `password` is 12 characters or more and at most 72 bytes; `phoneNumber` matches `^\+?[0-9]{8,15}$`;
  `fullName` 2–120 characters; `vehiclePlate` at most 20; `capacityKg` 1–5000. The app checks these first and
  shows identity's own messages for anything it refuses (`400`, a list of messages for validation).
- A `400` or `503` **after the account was created** carries `accountExists: true` and asks the courier to submit
  again with the same email and password; the app shows that text as it is. `409` means the email belongs to an
  account that cannot be resumed here.
- The account is pending until an administrator approves it. The app keeps the session and shows the waiting
  screen.

### 5.2 Sign-in, second factor, renewal, sign-out — identity

```
POST /api/v1/auth/login          { "email", "password" }
  200: { "accessToken", "refreshToken", "expiresIn", "tokenType", "user" }
  200: { "mfaRequired": true, "challengeToken", "expiresIn" }        (the account has a second factor)
  401: wrong email or password      400: invalid input      429: too many attempts

POST /api/v1/auth/2fa/verify     { "challengeToken", "code" }          (code: six digits)
  200: the session, as login        401: wrong code, or a challenge already answered or expired

POST /api/v1/auth/refresh        { "refreshToken" }                    (rotates the pair)
POST /api/v1/auth/logout         { "refreshToken" }, Authorization: Bearer <access token>     204
```

- The access token lives 15 minutes, the refresh token 30 days. Identity treats a refresh token presented twice as
  stolen, so the app renews one request at a time and stores the new pair in one write before using it.
- A challenge answers once; a wrong code does not spend it. After 300 s the courier signs in again.
- Enabling or disabling a second factor ends every other session; the courier's next renewal is refused and the
  app signs out.
- Sign-out ends the refresh family at identity before the phone forgets the session. If identity cannot be
  reached, the phone forgets it anyway.

### 5.3 May this account drive — matching

```
GET /api/v1/matching/driver/me   Authorization: Bearer <access token>
  200: { "data": { "id", "vehicle_plate", "capacity_kg", "status", "active" } }
  403: { "error": "pending_approval" }      404: { "error": "no_driver_record" }
  401: the token is refused                 503: identity could not be asked
```

Asked after sign-in, at start-up, and when the socket is refused twice. `pending_approval` (a courier never
approved, or deactivated) shows the waiting screen; `404` sends the courier to finish registering.

### 5.4 Socket & join — matching

- `wss://<edge>/ws/v1/matching/driver?vsn=2.0.0`. The access token travels in `Sec-WebSocket-Protocol`:
  `phoenix, base64url.bearer.phx.<the token in standard base64, without padding>`. It is never in the URL.
- Matching refuses at the upgrade: `403` with no body (bad or expired token, not a courier, no vehicle, pending
  or deactivated), `503` when identity could not be asked. The app renews once on a refusal; a second refusal
  asks 5.3 why. `503` and an unreachable edge are retried with backoff.
- After connecting, the app joins `driver:<driver_id>`; the reply is `{ "status": "online" | "busy" | "offline" }`.
  **Joining puts nobody on duty.** A join refused with `pending_approval` shows the waiting screen.
- Right after the join, matching pushes one `active_order` (5.6).
- A disconnect takes the courier off duty.

### 5.5 Messages the app SENDS (channel `push`)

| Event | Payload | Success reply | Error replies (`{reason}`) |
| :--- | :--- | :--- | :--- |
| `status` | `status`: `"online"` \| `"busy"` \| `"offline"` | `{status}`: what matching decided | `invalid_status`, `no_active_job` |
| `ping` | `latitude`, `longitude`, `recorded_at` (ISO 8601, the fix's own time), optional `speed_kmh`, `bearing_deg` | `ok` | `invalid_telemetry`, `rate_limited` |
| `ping_batch` | `pings`: up to 100 positions recorded offline, each with the `ping` fields, any order | `{stored, duplicates, refused: [{index, reason}]}` by index | `rate_limited`, `invalid_batch`, `batch_too_large`, `unavailable` |
| `pickup` | `order_id` | `ok` | `forbidden`, `invalid_transition`, `not_found`, `invalid_order_id` |
| `pod_upload` | `order_id`, `photo_sha256` | `{upload_url, upload_headers, photo_url}` | `invalid_photo_hash`, `invalid_transition`, … |
| `delivered` | `order_id`, `pod_photo_url`, `pod_signature` (`data:image/png;base64,…`) | `ok` | `signature_required`, `invalid_proof`, `proof_unverifiable`, `invalid_transition`, … |

- `status online` answers `busy` while the courier carries a job. While on duty the app sends `status online`
  after every join, then **one `ping` at once**, moved or not: matching dispatches only on a position received
  after the courier went on duty.
- A `ping` older than the position matching holds is ignored; one stamped more than five minutes ahead is
  `invalid_telemetry`; more than 100 in 10 s is `rate_limited`.
- `ping_batch` positions are history: matching stores them and never makes them the live position. One more than
  a day old is refused as `too_old`, one more than five minutes ahead as `ahead_of_server_clock`. An `ok` reply
  settles the whole batch; an error reply settles nothing. Batches have their own budget, 30 per 60 s.
- `order_id` must be a positive integer (`invalid_order_id` otherwise).
- A `pickup` or `delivered` repeated by the courier who made it answers `ok`, so a retry after a lost reply is
  success. `proof_unverifiable` means the bucket could not be asked: try again.
- The photo is PUT to `upload_url` with exactly `upload_headers`; it must be a JPEG whose SHA-256 is
  `photo_sha256`.

### 5.6 Messages the app RECEIVES

| Event | Payload | When |
| :--- | :--- | :--- |
| `active_order` | `{ "order": <order> \| null }` | right after the join, and after an `order_unassigned` |
| `order_assigned` | `<order>` | a fresh dispatch |
| `order_updated` | `<order>` | a change made on the server side (a cancellation, say) |
| `order_unassigned` | `{ "id" }` | an administrator took the job off the courier |

`<order>` is `id`, `status` (`assigned`/`picked_up`/`delivered`/`cancelled`), `weight_kg`,
`pickup {latitude, longitude}`, `dropoff {latitude, longitude}`, `assigned_at`. A job is never parsed without
`assigned_at`; a `pending` job is not the courier's.

### 5.7 Phoenix channel wire protocol

Every frame is `[join_ref, ref, topic, event, payload]` (serializer 2.0.0). Replies are `phx_reply`, correlated
by `ref`. A heartbeat (`phoenix` topic, `heartbeat` event) goes every 30 s. The app's `ChannelClient` implements
this over `web_socket_channel`'s `IOWebSocketChannel`.

---

## 6. Behaviour

### 6.1 Session

- Splash renews an expired access token, then asks 5.3: approved → tracking; pending → waiting screen; refused →
  sign-in. When matching cannot be asked, tracking opens and keeps trying.
- A refused socket is renewed once; a second refusal asks 5.3, and the answer decides between the waiting screen
  and sign-in. The courier is never signed out because a service could not be reached.

### 6.2 Connectivity

- One connection indicator: connected / connecting / reconnecting / offline.
- Backoff reconnect (1, 2, 4 … 30 s, with jitter), and at once when the app returns to the foreground.
- `pickup` and `delivered` are retried until answered.
- A position that cannot go live (no socket, not yet back on duty, a `ping` that failed) is kept in Hive and sent
  later with `ping_batch`, never as a live `ping`: oldest first, 100 at a time, one batch in flight, after the join,
  `status online` and the fresh live fix. A batch is deleted only when an `ok` reply settles it; an error reply keeps
  it for a retry with backoff (60 s after `rate_limited`). Positions older than a day are dropped on the phone. The
  queue holds at most 21,600 positions (a day at the four-second cadence), the oldest dropped first.

### 6.3 Position

- Location permission in the foreground and "always".
- While on duty, a `ping` every 4 s when the courier has moved 5 m or more since the last one sent.
- Android keeps streaming through geolocator's location foreground service, with its notification, while on
  duty; iOS through the `location` background mode.
- `rate_limited` pauses pings for 10 s; `invalid_telemetry` is shown (the phone's clock) and that fix is not sent
  again.

### 6.4 Duty

- A switch puts the courier on or off duty. The screen shows the availability matching decided (`busy` while
  carrying a job).

### 6.5 Jobs

- `order_assigned` or a non-null `active_order` opens the job: pickup, drop-off, weight, and "navigate" deep links.
- "Mark as Picked Up" while assigned; then the proof: a camera photo (at most 1920 px a side, JPEG quality 85) and
  the receiver's signature drawn on screen; "Mark as Delivered" only when both exist.
- `order_updated` cancelled shows "Order cancelled"; `order_unassigned` shows that dispatch took the job off the
  courier.

---

## 7. Screens (sealed `AppRoute`s)

| Route | Screen | Purpose |
| :--- | :--- | :--- |
| `SplashRoute` | Splash | Renew the session, ask the fleet, choose the next route |
| `LoginRoute` | Login | Email and password, then the code when a second factor is required |
| `RegisterRoute` | Register | Person, vehicle and password |
| `PendingApprovalRoute` | Waiting | The account is not approved (yet); back to sign-in signs out |
| `TrackingRoute` | Tracking (home) | Connection, duty switch, availability, last position |
| `OrderRoute(order)` | Job | Pickup and drop-off, the proof, pickup and deliver actions |

---

## 8. Technical Architecture

`CLAUDE.md` binds: MVVM, Navigator 2.0 over a sealed `AppRoute`, `get_it` + `injectable`, `freezed` models,
`Result`/`Failure`, repositories over services, no UseCase layer.

| Layer | Pieces |
| :--- | :--- |
| Services | `DriverApi` (Retrofit over Dio), `TokenStore` (secure storage, one record), `SessionRenewer`, `FleetStanding`, `ChannelClient` + `WsChannelSocket`, `LocationService`, `OfflinePositionStore` (Hive), `PodPhotoUploader` |
| Repositories | `SessionRepository` (sign-in, second factor, standing, sign-out), `ConnectionRepository` (socket, renewal, why a refusal), `DutyRepository` (duty, the live position and the offline queue), `OrderRepository` (jobs and proof) |
| ViewModels | Splash, Login, Register, PendingApproval, Tracking, Order |

`HTTP_BASE` and `WS_BASE` come from `--dart-define-from-file=dart_defines/<environment>.json`; there are no
defaults, and a build without them shows an error screen instead of starting.

---

## 9. Packages

| Package | Purpose |
| :--- | :--- |
| `web_socket_channel` | The socket (`IOWebSocketChannel`, which keeps the upgrade's HTTP status) |
| `dio`, `retrofit` | Identity and matching over HTTP; the photo upload |
| `geolocator` | Position stream, and its Android location foreground service |
| `permission_handler` | Location "always" and notification permissions |
| `flutter_secure_storage` | The session |
| `hive`, `hive_flutter` | Positions recorded offline, until a `ping_batch` settles them |
| `image_picker`, `signature`, `crypto` | The proof of delivery and its SHA-256 |
| `url_launcher` | Pickup and drop-off in the phone's map app |
| `provider`, `get_it`, `injectable`, `freezed`, `json_serializable` | The architecture |

---

## 10. Non-Functional Requirements

- **Battery:** balanced accuracy; no ping while standing still; one socket, no polling.
- **Resilience:** reconnect within seconds of signal returning; lifecycle actions are idempotent at matching and
  retried; a job is never lost to a disconnect (`active_order` restores it).
- **Background execution:** a location foreground service on Android and the location background mode on iOS,
  with the permission prompts and store-review justifications they need.
- **Type safety:** every payload is parsed into a `freezed` model at the repository boundary.
- **Security:** TLS only, no cleartext in any build; the session in secure storage only; the token never in a URL
  or a log; no precise coordinates logged in release builds.

---

## 11. Success Metrics

- **Connectivity:** connected for at least 99% of on-duty time on normal mobile data.
- **Freshness:** dispatch sees a position within about a second of a ping, and a courier going on duty is
  dispatchable at once.
- **Reliability:** every pickup and delivery is eventually acknowledged; none is shown as failed after it
  succeeded.
- **Battery:** under about 5% an hour attributable to the app while on duty (device-dependent target).

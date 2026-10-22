# Kinetix Courier Mobile App (`kinetix-courier-mobile`)

The courier's app for the Kinetix fleet, in Flutter for Android and iOS, managed with FVM. A courier registers,
waits for an administrator's approval, signs in (with a second factor when the account has one), goes on duty,
streams its position to `kinetix-matching-service` (keeping what it records offline in Hive and sending it
later as history), and carries jobs from pickup to a delivery proved by a photo
and the receiver's signature.

Every call goes through the edge, Kong (`kinetix-api-gateway`), over TLS:

| What | Where | Owner |
| --- | --- | --- |
| Register a courier | `POST /api/v1/couriers/register` | identity |
| Sign in, second factor, renew, sign out | `POST /api/v1/auth/login`, `/2fa/verify`, `/refresh`, `/logout` | identity |
| May this account drive? | `GET /api/v1/matching/driver/me` | matching |
| Duty, position, positions recorded offline (`ping_batch`), jobs, proof of delivery | WebSocket `/ws/v1/matching/driver?vsn=2.0.0` (Phoenix channel `driver:<id>`) | matching |
| The delivery photo | the presigned `PUT` matching hands out (`pod_upload`) | object store, through Kong |

`PRD.md` describes the contract and the behaviour, and `CLAUDE.md` the architecture and the decisions the code
cannot explain.

## Running it

The app has no built-in addresses. `HTTP_BASE` and `WS_BASE` come from a file in `dart_defines/`, and a build
without them opens a screen that says what is missing.

```bash
fvm flutter pub get

fvm flutter run --dart-define-from-file=dart_defines/lab.json

bin/build production apk
bin/build production appbundle
bin/build production ipa
```

`dart_defines/lab.json` names the lab's edge, `https://localhost:8443`. On an Android emulator, forward it with
`adb reverse tcp:8443 tcp:8443`. The lab's certificate is issued by the lab's own CA, which the phone must trust.

## Checks

```bash
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter analyze
fvm flutter test --coverage
fvm flutter test integration_test -d flutter-tester
```

CI (`.github/workflows/ci.yaml`, `.gitlab-ci.yml`) runs the same, and fails under 70% line coverage.
`integration_test/app_flow_test.dart` drives the whole app with fake repositories; it runs headless on
`flutter-tester` and on a device alike.

## Layout

```
lib/
├── config/        AppConfig (the dart defines) and AppConfigCheck (refuses to start without them)
├── core/          Result, the Failure hierarchy, the logger
├── di/            get_it + injectable; injection.config.dart is generated
├── models/        freezed models, ids, enums
├── repositories/  Session, Connection, Duty and Order repositories: the domain boundary
├── routes/        the sealed AppRoute and the Navigator 2.0 router
├── services/
│   ├── auth/      DriverApi (Retrofit), TokenStore, SessionRenewer, FleetStanding
│   ├── channel/   ChannelClient (the Phoenix protocol) over WsChannelSocket
│   ├── location/  LocationService (geolocator, with its Android foreground service)
│   ├── offline/   OfflinePositionStore: positions recorded without a connection, in Hive
│   └── storage/   PodPhotoUploader
├── state/         sealed UI states and domain events
├── ui/            screens and widgets
└── viewmodels/    one ChangeNotifier per screen
```

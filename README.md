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

Registration, sign-in, the second factor and renewal also carry `X-Kinetix-Client: courier-app` and a Firebase App
Check token (`X-Firebase-AppCheck`): Play Integrity on Android, App Attest on iOS, the debug provider in lab debug
builds only.
| May this account drive? | `GET /api/v1/matching/driver/me` | matching |
| Duty, position, positions recorded offline (`ping_batch`), jobs, proof of delivery | WebSocket `/ws/v1/matching/driver?vsn=2.0.0` (Phoenix channel `driver:<id>`) | matching |
| The delivery photo | the presigned `PUT` matching hands out (`pod_upload`) | object store, through Kong |

`PRD.md` describes the contract and the behaviour, and `CLAUDE.md` the architecture and the decisions the code
cannot explain.

## Running it

The app has no built-in addresses. `HTTP_BASE`, `WS_BASE`, `APP_CHECK_PROVIDER` and the Firebase values
(`FIREBASE_PROJECT_ID`, `FIREBASE_MESSAGING_SENDER_ID` = the project number, `FIREBASE_API_KEY_ANDROID`,
`FIREBASE_APP_ID_ANDROID`, `FIREBASE_API_KEY_IOS`, `FIREBASE_APP_ID_IOS`) come from a file in `dart_defines/`, and a
build missing any of them opens a screen that says what is missing. The Firebase values are empty until they are
copied from the Firebase console; `CLAUDE.md` ("The app proves itself to identity") lists the console steps.

```bash
fvm flutter pub get

fvm flutter run --dart-define-from-file=dart_defines/lab.json

bin/build production apk
bin/build production appbundle
bin/build production ipa
```

`bin/build lab` makes a debug build (the App Check debug provider; its token is printed in logcat or the Xcode
console and registered in the Firebase console), `bin/build production` a release build, which never uses the
debug provider. `dart_defines/lab.json` names the lab's edge, `https://localhost:8443`. On an Android emulator, forward it with
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
│   ├── attestation/ ClientProof (App Check tokens, one retry) and AppCheckActivation (Firebase start-up)
│   ├── auth/      DriverApi (Retrofit), TokenStore, SessionRenewer, FleetStanding
│   ├── channel/   ChannelClient (the Phoenix protocol) over WsChannelSocket
│   ├── location/  LocationService (geolocator, with its Android foreground service)
│   ├── offline/   OfflinePositionStore: positions recorded without a connection, in Hive
│   └── storage/   PodPhotoUploader, ProofDraftStore (the proof of delivery until it is answered)
├── state/         sealed UI states and domain events
├── ui/            screens and widgets
└── viewmodels/    one ChangeNotifier per screen
```

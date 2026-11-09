# AGENTS.md — Enterprise Flutter Architecture

These instructions MUST be followed by the AI assistant (Agents) when interacting with this project or generating new Flutter code.

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

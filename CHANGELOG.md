# Changelog — Kortex

Notable changes to this repository. Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning: [SemVer](https://semver.org/lang/en/). Categories: `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security`.

## How this file is maintained

- **Who writes it**: whoever makes the change. An observable change is listed under `[Unpublished]` in the same commit as the change.
- **When it becomes a release**: promoted to a dated section matching the `vX.Y.Z` tag.
- **Do not confuse with `LEARNINGS.md`**: that is the technical diary; this is the release line.

## [Unpublished]

### Fixed

- `KortexScope` no longer leaks its state when a provider's `create` throws during eager creation. The eager creation moved from `initState` to the first `build`, so the scope element mounts normally and is disposed by the framework instead of being left alive.

### Added

- Memory-leak gate for the whole test suite: `test/flutter_test_config.dart` enables `LeakTesting` (off by default in `flutter_test`), and `test/kortex_leak_gate_test.dart` proves the gate detects an undisposed object.
- Windows desktop runner for the example app (`example/windows/`), so it can be launched with `flutter run -d windows`.

## [0.1.1] - 2026-11-20

### Changed

- Public surfaces translated to English for global reach on pub.dev: `README.md`, `CHANGELOG.md`, every public doc comment in `lib/`, the `example/` app and the pubspec descriptions (`UC-05.05`). Internal governance (`docs/`, `AGENTS.md`, `LEARNINGS.md`, `CHECKPOINT.md`, `docs/plan/`) stays in Brazilian Portuguese.
- The declared Flutter floor is now the measured one — `flutter: ">=3.47.6"`, the first release shipping Dart 3.13.5 — in all three pubspecs. The previous `>=1.17.0` came from the `flutter create` template and advertised a compatibility the code cannot honor.
- The `poc/` proof of concept is excluded from the published archive via `.pubignore`; it keeps `package:poc/...` imports that do not resolve for consumers, and it is not part of the public API.

### Added

- `poc/` proof of concept (EPIC05): sealed `Result<T>`, immutable `Task` + `TaskTitle` value object, `TaskRepository` port and adapter (`UC-05.01`).
- `poc/` proof of concept (EPIC05): second aggregate `Category` (validated value objects, cross-aggregate invariant), 9 commands/queries and the `TaskUseCases` facade in VSA layout (`UC-05.02`).
- `poc/` proof of concept (EPIC05): `TasksController`, `TasksPage` and widgets with a reactive form draft (`UC-05.03`).
- Technical visits app in `poc/` (EPIC06): `Visit`/`ChecklistItem`/`Client`/`Technician` domain with validated value objects, `VisitStatus`, three ports and three stores with simulated latency and failure (`UC-06.01`).
- Technical visits app in `poc/` (EPIC06): five commands, the visit listing query with client/technician join and the `VisitUseCases` facade (`UC-06.02`).
- Technical visits app in `poc/` (EPIC06): `VisitsController` on `KortexResource`/`KortexCommand`, `VisitsPage` with the three async states plus a status filter and `KortexListener`, new-visit dialog through `KortexScope.capture`, and `overrides`-driven retry test (`UC-06.03`, EPIC06 completed).
- Technical visits app in `poc/` (EPIC07): `ScheduledAt` value object with injected `now`, clients screen with search and create dialog, daily agenda with day selector, and a three-area `NavigationBar` shell; providers created once per area so tab switching keeps state (`UC-07.01..03`, EPIC07 completed).

## [0.1.0] - 2026-11-20

### Added

- `IKortexDisposable`, `KortexDisposeBag` and `IKortexController` in `lib/src/reactive/` with idempotent LIFO disposal and `onDispose` running before the bag (`UC-01.01`).
- `KortexTracker` (deduplicated queue, `kortexBatch`, `kortexUntracked`), `IKortexReadonlySignal` and `KortexSignal` with configurable `equals` and post-`dispose` access blocking (`UC-01.02`).
- `lib/src/reactive/reactive.dart` barrel re-exporting the reactive layer from a single import.
- `KortexComputed` (lazy, cached, cascading invalidation, downstream `equals`) and `KortexEffect` (`onCleanup`, `debounce`, re-entrancy guard) (`UC-01.03`, EPIC01 completed).
- Sealed `IKortexAsyncState` and `KortexResource` with `previousValue` and monotonic-generation disposal (`UC-02.01`).
- `KortexStreamResource` (cancellation + generation-guarded `restart`), `toStream()` and `KortexCommand` (re-entrancy lock) (`UC-02.02`, EPIC02 completed).
- `KortexProvider`, `KortexScope` (sibling resolution, chained cycle detection, `lazy`, LIFO disposal, instance preservation across rebuilds) and `readKortex`/`watchKortex` (`UC-03.01`).
- `KortexScope.capture` (explicit type token), `overrides` and tree resolution (`UC-03.02`, EPIC03 completed).
- `IKortexPage`, `KortexWatch` (static child, `setState` outside the build phase) and `KortexSelector` (internal derived value + internal `Watch`, rebuild only on change) (`UC-04.01`).
- `KortexListener` (separate `watch`, `fireImmediately`, post-frame deferral), `KortexResourceBuilder` (exhaustive `switch`) and `Listenable`/`ValueListenable`/`toListenable` bridges (`UC-04.02`).
- Public barrel `lib/kortex.dart` (hides `KortexTracker`) and the `example/` app with `CounterPage`, sibling `KortexScope` and smoke test (`UC-04.03`).
- Initial Flutter package skeleton for `kortex` (`pubspec.yaml`, `analysis_options.yaml`, `lib/kortex.dart`).
- Product and architecture documentation for `v0.1.0` in `docs/product/PRD.md` and `docs/architecture/SPEC.md` (pure-Dart reactivity, `KortexScope`, `StatelessWidget`-first `IKortexPage`, `Stream`/`ValueListenable`/`Listenable` bridges, Anti-GetX guardrails and the `I-` naming convention).

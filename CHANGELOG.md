# Changelog — Kortex

Notable changes to this repository. Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning: [SemVer](https://semver.org/lang/en/). Categories: `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security`.

## How this file is maintained

- **Who writes it**: whoever makes the change. An observable change is listed under `[Unpublished]` in the same commit as the change.
- **When it becomes a release**: promoted to a dated section matching the `vX.Y.Z` tag.
- **Do not confuse with `LEARNINGS.md`**: that is the technical diary; this is the release line.

## [Unpublished]

### Changed

- Public surfaces translated to English for global reach on pub.dev: `README.md`, `CHANGELOG.md`, every public doc comment in `lib/`, the `example/` app and the pubspec descriptions (`UC-05.05`). Internal governance (`docs/`, `AGENTS.md`, `LEARNINGS.md`, `CHECKPOINT.md`, `docs/plan/`) stays in Brazilian Portuguese.

### Added

- `poc/` proof of concept (EPIC05): sealed `Result<T>`, immutable `Task` + `TaskTitle` value object, `TaskRepository` port and adapter (`UC-05.01`).
- `poc/` proof of concept (EPIC05): second aggregate `Category` (validated value objects, cross-aggregate invariant), 9 commands/queries and the `TaskUseCases` facade in VSA layout (`UC-05.02`).
- Publishable minimal `example/` app (counter + save, CI extended to cover `example/`, `dry-run` includes it without dotfiles) (`UC-05.04`).

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

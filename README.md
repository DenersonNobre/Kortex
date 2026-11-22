# Kortex

Minimal Dart/Flutter package with **zero third-party dependencies** (`sdk: flutter`) for fine-grained signal reactivity, explicit dependency scoping in the widget tree (`KortexScope`), and UI built primarily with `StatelessWidget` (`IKortexPage`).

> **Status**: `v0.2.1` — reactive core, reactive collections (`KortexList`, `KortexMap`), scoped dependency injection, and widget layer are implemented and tested.

---

## Why Kortex?

- **Zero third-party dependencies**: only `flutter` (`sdk: flutter`) in `dependencies`.
- **Explicit & scoped by construction**: no global Service Locator (`put`/`find`), no global `EventBus`, no custom router, no context-free helpers, no magic `onInit`.
- **Real encapsulation**: `IKortexReadonlySignal<T>` exposes reactive reads to the UI while `KortexSignal<T>` stays private inside the controller.
- **`StatelessWidget`-first UI**: `IKortexPage<TController>`, `KortexWatch`, `KortexSelector<T>`, `KortexListener<T>` and `KortexResourceBuilder<T>` encapsulate their `StatefulWidget`s internally.
- **Deterministic lifecycle**: instances registered in `KortexScope` are disposed in reverse order when the subtree unmounts.

---

## Layered Architecture

- **`lib/src/reactive/` (pure Dart)**: `KortexSignal`, `IKortexReadonlySignal`, `KortexComputed`, `KortexEffect`, `KortexList`, `IKortexReadonlyList`, `KortexMap`, `IKortexReadonlyMap`, `kortexBatch`, `kortexUntracked`, `KortexResource`, `KortexStreamResource`, `KortexCommand`, `IKortexDisposable`, `KortexDisposeBag`, `IKortexController` — no `package:flutter/widgets.dart` import anywhere.
- **`lib/src/scope/` (Flutter SDK)**: `KortexProvider<T>` (`eager`, `lazy`, `.value`), `KortexScope` (hierarchical and sibling resolution with cycle detection, `overrides` for tests, and `KortexScope.capture` for modals/dialogs in the `Overlay`) plus `readKortex<T>()` / `watchKortex<T>()` extensions on `BuildContext`.
- **`lib/src/widgets/` (Flutter SDK)**: `IKortexPage<TController>`, `KortexWatch`, `KortexSelector<T>`, `KortexListener<T>`, `KortexResourceBuilder<T>` and bridges to `Listenable` / `ValueListenable<T>` (`toKortexSignal()`, `toKortexSignalWith()`, `toListenable()`).

---

## Quick Example

```dart
class CounterController extends IKortexController {
  CounterController() {
    autoDispose(_count);
  }

  final _count = 0.kortex;
  IKortexReadonlySignal<int> get count => _count.readonly;

  void increment() => _count.update((value) => value + 1);
}

class CounterPage extends IKortexPage<CounterController> {
  const CounterPage({super.key});

  @override
  Widget buildPage(BuildContext context, CounterController controller) {
    return KortexWatch(
      builder: (context, child) => Text('Clicks: ${controller.count.value}'),
    );
  }
}

// Composition root
KortexScope(
  providers: [
    KortexProvider<CounterController>(create: (_) => CounterController()),
  ],
  child: const MaterialApp(home: CounterPage()),
);
```

---

## Roadmap

Planned improvements that preserve Kortex's core constraints (zero third-party dependencies, pure-Dart reactivity, and explicit widget-tree scoping):

- **`v0.2.0` (Ergonomics & SDK reach)**:
  - Lower the minimum Dart/Flutter SDK constraint in `pubspec.yaml` after CI matrix verification.
  - `KortexSet<E>` (`IKortexReadonlySet<E>`) to complete the reactive collection trio alongside `KortexList` and `KortexMap`.
  - `canExecute` reactive guard on `KortexCommand`.
  - `KortexEffect.once` (auto-disposing single-shot effect) and `throttle` option alongside `debounce`.
  - `runIfActive` guard on `IKortexController` for ad-hoc async methods.
- **`v0.3.0` (Observability & DX)**:
  - Opt-in scope lifecycle hook for debug inspection (without global singletons).
  - Native `dart:developer` service extensions for Flutter DevTools inspection.
- **Separate companion packages** (keeping `kortex` dependency-free):
  - Optional static-analysis lints (e.g. detecting signals created without `autoDispose`) and optional signal persistence adapters.

---

## Canonical Documentation

- **Product Requirements**: [docs/product/PRD.md](docs/product/PRD.md)
- **Domain Technical Specification**: [docs/architecture/SPEC.md](docs/architecture/SPEC.md)
- **Changelog**: [CHANGELOG.md](CHANGELOG.md)

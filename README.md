# Kortex

Minimal Dart/Flutter package with **zero third-party dependencies** (`sdk: flutter`) for fine-grained signal reactivity, explicit dependency scoping in the widget tree (`KortexScope`), and UI built primarily with `StatelessWidget` (`IKortexPage`).

> **Status**: `v0.1.0` published — reactive core, scoped dependency injection, and widget layer are implemented, tested and released.

---

## Why Kortex?

- **Zero third-party dependencies**: only `flutter` (`sdk: flutter`) in `dependencies`.
- **Anti-GetX by construction**: no global Service Locator (`put`/`find`), no global `EventBus`, no custom router, no context-free helpers, no magic `onInit`.
- **Real encapsulation**: `IKortexReadonlySignal<T>` exposes reactive reads to the UI while `KortexSignal<T>` stays private inside the controller.
- **`StatelessWidget`-first UI**: `IKortexPage<TController>`, `KortexWatch`, `KortexSelector<T>`, `KortexListener<T>` and `KortexResourceBuilder<T>` encapsulate their `StatefulWidget`s internally.
- **Deterministic lifecycle**: instances registered in `KortexScope` are disposed in reverse order when the subtree unmounts.

---

## Layered Architecture

- **`lib/src/reactive/` (pure Dart)**: `KortexSignal`, `IKortexReadonlySignal`, `KortexComputed`, `KortexEffect`, `kortexBatch`, `kortexUntracked`, `KortexResource`, `KortexStreamResource`, `KortexCommand`, `IKortexDisposable`, `KortexDisposeBag`, `IKortexController` — no `package:flutter/widgets.dart` import anywhere.
- **`lib/src/scope/` (Flutter SDK)**: `KortexProvider<T>` (`eager`, `lazy`, `.value`), `KortexScope` (hierarchical and sibling resolution with cycle detection, `overrides` for tests, and `KortexScope.capture` for modals/dialogs in the `Overlay`) plus `readKortex<T>()` / `watchKortex<T>()` extensions on `BuildContext`.
- **`lib/src/widgets/` (Flutter SDK)**: `IKortexPage<TController>`, `KortexWatch`, `KortexSelector<T>`, `KortexListener<T>`, `KortexResourceBuilder<T>` and bridges to `Listenable` / `ValueListenable<T>` (`toKortexSignal()`, `toKortexSignalWith()`, `toListenable()`).

---

## Quick Example

```dart
class CounterController extends IKortexController {
  CounterController() {
    autoDispose(count);
  }

  final KortexSignal<int> count = KortexSignal(0);

  void increment() => count.update((value) => value + 1);
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

## Canonical Documentation

- **Product Requirements**: [docs/product/PRD.md](docs/product/PRD.md)
- **Domain Technical Specification**: [docs/architecture/SPEC.md](docs/architecture/SPEC.md)
- **Changelog**: [CHANGELOG.md](CHANGELOG.md)

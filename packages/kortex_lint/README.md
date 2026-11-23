# kortex_lint

Static analysis lints for [`kortex`](https://pub.dev/packages/kortex) powered by the official Dart `analysis_server_plugin` API.

## Installation

Add `kortex_lint` to `dev_dependencies` (or enable it under `plugins:` in your `analysis_options.yaml`):

```yaml
plugins:
  kortex_lint: ^0.1.0
```

## Rules

- **`avoid_undisposed_kortex_signal`**: warns when a reactive primitive (`KortexSignal`, `KortexComputed`, `KortexEffect`, `KortexResource`, `KortexStreamResource`, `KortexCommand`, `KortexList`, `KortexMap`, `KortexSet`, or `.kortex*`) is declared in an `IKortexController` without being registered via `autoDispose(...)`, `disposeBag.add(...)`, or `.dispose()`.
- **`avoid_kortex_signal_in_build`**: warns when a reactive Kortex primitive is created inside `build()` or `buildPage()`, where it would be recreated on every widget rebuild.

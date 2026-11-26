# kortex_persist

Reactive persistence and hydration for [`kortex`](https://pub.dev/packages/kortex) signals, with pluggable storage (`IKortexStorage`) and **zero third-party dependencies**.

## Why `kortex_persist`?

Without it, every controller that persists local state (theme, filters, form drafts, preferences) repeats the same error-prone boilerplate:

1. Reading from storage asynchronously in the constructor and checking `if (!isDisposed)` before updating the signal;
2. Writing back to storage on every signal mutation;
3. Keeping `clear()` synchronized between storage and in-memory state.

`KortexPersistedSignal<T>` turns that into a single reactive primitive: it **hydrates automatically** (`hydrated`), **persists on every change**, **guards against post-`dispose` writes**, and **resets cleanly** via `clear()`.

## Pluggable Storage (`IKortexStorage`)

`kortex_persist` does not lock you into a specific database. Implement `IKortexStorage` (3 methods: `read`, `write`, `delete`) for `SharedPreferences`, `sqflite`, or `flutter_secure_storage`, and use `KortexMemoryStorage` in tests.

## Usage

```dart
final storage = KortexMemoryStorage();

final darkMode = kortexPersistedSignal<bool>(
  key: 'dark_mode',
  initialValue: false,
  storage: storage,
  encode: (v) => v.toString(),
  decode: (raw) => raw == 'true',
);

await darkMode.hydrated; // loads persisted value if present
darkMode.value = true;   // automatically persisted
await darkMode.clear();  // removes from storage and resets to initialValue
```

## Quando usar / Quando NÃO usar

- **Quando usar**: preferências simples, filtros de UI ou rascunhos leves que precisam sobreviver à reabertura do app com `KortexPersistedSignal` + `IKortexStorage`.
- **Quando NÃO usar**: bancos relacionais, consultas complexas ou segredos críticos sem armazenamento seguro dedicado.

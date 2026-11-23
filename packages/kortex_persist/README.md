# kortex_persist

Reactive persistence and hydration adapters for [`kortex`](https://pub.dev/packages/kortex) signals, with pluggable storage (`IKortexStorage`).

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

await darkMode.hydrated;
darkMode.value = true; // automatically persisted
```

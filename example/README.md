# Example — Kortex (pub.dev)

Minimal example of the [`kortex`](../README.md) package for the pub.dev
Example tab: reactive counter plus async saving with a double-trigger lock,
using only the public API (`package:kortex/kortex.dart`).

The richer proof of concept used during development (full VSA layout, two
aggregates, `Result`, use-case facade) lives in [`../poc/`](../poc/README.md).

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

# kortex_forms

Reactive, testable form and field state management for [`kortex`](https://pub.dev/packages/kortex) without `GlobalKey<FormState>`.

## Why `kortex_forms`?

Flutter's built-in `Form` couples validation to `BuildContext` and `GlobalKey<FormState>`, making unit testing form logic harder. `KortexField<T>` and `KortexForm` keep form state, `touched`/`dirty` flags, and validation in pure reactive Dart — testable without widgets.

## Usage

```dart
final email = kortexField<String>(
  '',
  validators: [(v) => v.contains('@') ? null : 'Invalid email'],
);
final form = kortexForm([email]);

if (form.validate()) {
  // submit email.value
}
```

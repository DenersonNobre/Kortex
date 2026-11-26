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

## Quando usar / Quando NÃO usar

- **Quando usar**: formulários reativos com validação síncrona, rastreamento de `dirty`/`touched` e `reset()` seguro (incluindo campos nullable).
- **Quando NÃO usar**: regras de negócio de domínio/invariantes de agregado (devem ficar na camada de domínio, não em validadores de UI).

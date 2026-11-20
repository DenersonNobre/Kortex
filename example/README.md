# Exemplo — Kortex (pub.dev)

Exemplo mínimo do pacote [`kortex`](../README.md) para a aba Example do
pub.dev: contador reativo + salvamento assíncrono com trava de duplo
clique, usando só a API pública (`package:kortex/kortex.dart`).

A POC robusta de desenvolvimento (VSA completo, dois agregados,
`Result`, fachada) vive em [`../poc/`](../poc/README.md).

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

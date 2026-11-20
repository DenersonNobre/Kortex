# Exemplo — Kortex

App mínimo que exercita o pacote `kortex` de ponta a ponta usando apenas
a API pública (`package:kortex/kortex.dart`):

- `KortexScope` com `datasource → repository → controller` (resolução entre irmãos);
- `IKortexPage` (`StatelessWidget`) + `IKortexController` sem `onInit` mágico;
- `KortexWatch` (contador), `KortexSelector` (par/ímpar) e `KortexListener` (`SnackBar` ao salvar);
- `KortexResource` (mensagem assíncrona com `previousValue` + retentativa) e `KortexCommand` com trava de duplo clique.

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

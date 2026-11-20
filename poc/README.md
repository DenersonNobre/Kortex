# POC — Kortex

App de demonstração do pacote `kortex` usando apenas a API pública
(`package:kortex/kortex.dart`), organizado no layout VSA do Oráculo
(`app/`, `core/`, `modules/<contexto>/{commands,data,domain,ui}` com
barrels `.index.dart`):

- Domínio puro em Dart: `Task`/`Category` imutáveis, VOs validados
  (`TaskTitle`, `CategoryName`, `CategoryColor`) e `Result<T>` selado —
  nenhuma exceção para falha esperada;
- Ports (`TaskRepository`, `CategoryRepository`) + adapters em memória;
- 9 commands/queries + fachada `TaskUseCases` (1 dependência no controller);
- `TasksPage` (`IKortexPage`, `StatelessWidget`) com `KortexWatch`,
  `KortexSelector` e `KortexListener` (`SnackBar` de erro/sucesso).

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

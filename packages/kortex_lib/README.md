# kortex_lib

Utility suite for [`kortex`](https://pub.dev/packages/kortex) applications, re-exporting `package:kortex/kortex.dart` alongside:

- **`brlib`**: Brazilian validators and formatters (CPF, CNPJ, CEP, UF, phone, BRL currency, `Endereco`, input formatters).
- **`core`**: `Result`, `Failure`, `Logger`, `SecretCipher`, `Debouncer`, `AsyncCache`, `AsyncLock`, `StateMachine`, `Specification`, `PageResult`, `UserSession`, and validators.
- **`rest`**: HTTP client, retry client, middleware, and REST datasource helpers.
- **`sqlite`**: SQLite provider and migration helpers.
- **`widgets`**: Reusable Material UI widgets (`AsyncButton`, `BusyOverlay`, `CardTile`, `SearchPanel`, `ConfirmDialog`, `PillField`, `StatTile`, `StateViews`, etc.).

## Usage

```dart
import 'package:kortex_lib/kortex_lib.dart';
```

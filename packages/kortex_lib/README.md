# kortex_lib

Utility toolkit for [`kortex`](https://pub.dev/packages/kortex) apps, bundling commonly used building blocks for Flutter/Dart projects.

## What's included

- **`brlib`** — Brazilian validators and formatters (CPF/CNPJ, CEP, phone, money) and input formatters.
- **`core`** — helpers, logging, models, patterns (`Result`, `AsyncLock`, `Debouncer`, `Specification`, etc.), security, services, and validators.
- **`rest`** — REST client stack with auth, retry, circuit breaker, logging, and datasource helpers.
- **`sqlite`** — SQLite datasource, migration, provider, and unit-of-work helpers.
- **`widgets`** — reusable UI widgets (alerts, modals, state views, labels, tiles, and more).

`kortex_lib` also re-exports `package:kortex/kortex.dart` for convenience.

## Installation

```yaml
dependencies:
  kortex_lib: ^0.1.0
```

## Usage

```dart
import 'package:kortex_lib/kortex_lib.dart';

// brlib: Brazilian document validation/formatting
final cpf = Cpf.tryParse('52998224725');
print(cpf.isSuccess); // true
print(cpf.value?.formatted); // 529.982.247-25

// core: Result pattern
IResult<int, IFailure> parsePositive(String raw) {
  final value = int.tryParse(raw);
  if (value == null || value <= 0) {
    return const ValidationFailure('Value must be a positive integer')
        .toFailure<int>();
  }
  return value.toSuccess<IFailure>();
}
```

## Modules

Import only what you need:

```dart
import 'package:kortex_lib/brlib/brlib.dart';
import 'package:kortex_lib/core/core.dart';
import 'package:kortex_lib/rest/rest.dart';
import 'package:kortex_lib/sqlite/sqlite.dart';
import 'package:kortex_lib/widgets/widgets.dart';
```

## License

MIT — see [LICENSE](LICENSE).

# kortex_lib

Utility suite for [`kortex`](https://pub.dev/packages/kortex) applications, re-exporting `package:kortex/kortex.dart` alongside:

- **`core`**: `Result`, `Failure`, `Logger`, `SecretCipher`, `Debouncer`, `AsyncCache`, `AsyncLock`, `StateMachine`, `Specification`, `PageResult`, `UserSession`, and validators.
- **`rest`**: HTTP client, retry client, middleware, and REST datasource helpers.
- **`sqlite`**: SQLite provider and migration helpers.

## Usage

```dart
import 'package:kortex_lib/kortex_lib.dart';
```

## Política de Dependências & Fronteira de API

- **Fronteira estrita de exports**: apenas `lib/kortex_lib.dart` e os barrels de eixo (`core`, `brlib`, `rest`, `sqlite`, `widgets`) compõem a API pública; detalhes internos devem permanecer fora dos exports públicos.
- **Sem duplicação de núcleo**: `kortex_lib` não duplica primitivas reativas nem de ciclo de vida de `kortex` (apenas re-exporta `package:kortex/kortex.dart` e `package:kortex_forms/kortex_forms.dart`).
- **Critério de split**: quando um eixo específico (ex.: `brlib`, `rest`, `sqlite`, `widgets`) ganhar massa crítica, dependências pesadas ou ciclo de release próprio, deve ser extraído para pacote dedicado (`kortex_br`, etc.).

## Quando usar / Quando NÃO usar

- **Quando usar**: `IResult`/`IUseCase`, `PageResult` e utilitários compartilhados entre múltiplos módulos/apps.
- **Quando NÃO usar**: não usar `SecretCipher` para proteção de segredos críticos em produção (AES-CFB64 sem AEAD/salt), nem duplicar primitivas reativas de `kortex`.

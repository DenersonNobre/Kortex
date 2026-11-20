/// Barrel da camada de escopo (`lib/src/scope/`).
///
/// SRP: reexportar providers, escopo e extensões de contexto num import.
/// NÃO faz: expor captura de `Overlay` (papel de `KortexScope.capture`
/// na `UC-03.02`) nem estado global.
///
/// Uso: `import 'package:kortex/src/scope/scope.dart';`
library;

export 'kortex_context_extensions.dart';
export 'kortex_provider.dart';
export 'kortex_scope.dart';

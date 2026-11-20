/// Barrel da camada reativa pura (`lib/src/reactive/`).
///
/// SRP: reexportar a API pública da camada num único import. NÃO faz:
/// esconder coordenadores internos (isso é papel de `lib/kortex.dart`
/// na `UC-04.03`) nem importar Flutter/`BuildContext`.
///
/// Uso interno e em testes:
/// `import 'package:kortex/src/reactive/reactive.dart';`
library;

export 'kortex_computed.dart';
export 'kortex_controller.dart';
export 'kortex_disposable.dart';
export 'kortex_effect.dart';
export 'kortex_observer.dart';
export 'kortex_resource.dart';
export 'kortex_signal.dart';

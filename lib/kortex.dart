/// API pública do pacote `kortex`.
///
/// SRP: reexportar a superfície pública das três camadas num único import,
/// ocultando coordenadores internos (`KortexTracker`). NÃO faz: expor
/// `BuildContext` sem escopo nem estado global.
///
/// Uso: `import 'package:kortex/kortex.dart';`
library;

export 'src/reactive/reactive.dart' hide KortexTracker;
export 'src/scope/scope.dart';
export 'src/widgets/widgets.dart';

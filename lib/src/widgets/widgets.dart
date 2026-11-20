/// Barrel da camada de widgets (`lib/src/widgets/`).
///
/// SRP: reexportar página, trechos reativos e (na `UC-04.02`) ouvinte,
/// construtor de recurso e pontes `Listenable` num único import. NÃO faz:
/// expor coordenadores internos.
///
/// Uso: `import 'package:kortex/src/widgets/widgets.dart';`
library;

export 'kortex_page.dart';
export 'kortex_selector.dart';
export 'kortex_watch.dart';

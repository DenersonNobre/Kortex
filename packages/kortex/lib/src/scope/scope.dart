/// Barrel of the scope layer (`lib/src/scope/`).
///
/// SRP: re-export providers, scope and context extensions from one import.
/// It does NOT expose the `Overlay` capture (that is `KortexScope.capture`
/// at `UC-03.02`) nor global state.
///
/// Usage: `import 'package:kortex/src/scope/scope.dart';`
library;

export 'kortex_context_extensions.dart';
export 'kortex_provider.dart';
export 'kortex_scope.dart';

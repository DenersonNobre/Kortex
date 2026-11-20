/// Public API of the `kortex` package.
///
/// SRP: re-export the public surface of the three layers from a single
/// import, hiding internal coordinators (`KortexTracker`). It does NOT expose
/// `BuildContext` without a scope nor global state.
///
/// Usage: `import 'package:kortex/kortex.dart';`
library;

export 'src/reactive/reactive.dart' hide KortexTracker;
export 'src/scope/scope.dart';
export 'src/widgets/widgets.dart';

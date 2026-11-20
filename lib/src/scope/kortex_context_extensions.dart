/// `BuildContext` extensions for resolution inside the `KortexScope`.
///
/// SRP: expose `read` (no subscription) and `watch` (with rebuild) as
/// context syntax. It does NOT resolve outside a `KortexScope` — without an
/// ancestor scope it throws a `StateError`.
///
/// Dependencies: `package:flutter/widgets.dart` + `kortex_scope.dart`.
library;

import 'package:flutter/widgets.dart';

import 'kortex_scope.dart';

/// Dependency reads from the `KortexScope` through `BuildContext`.
extension KortexContextReader on BuildContext {
  /// Resolves [T] without subscribing to the scope (no rebuild on updates).
  T readKortex<T>() =>
      KortexScope.resolveKortexDependency<T>(this, listen: false);

  /// Resolves [T] subscribing to the scopes (rebuilds when they update).
  T watchKortex<T>() =>
      KortexScope.resolveKortexDependency<T>(this, listen: true);
}

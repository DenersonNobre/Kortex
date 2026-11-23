/// Base controller with an explicit lifecycle (`IKortexController`).
///
/// SRP: provide an integrated `KortexDisposeBag` and an `onDispose()` hook
/// for controllers, without initialization magic (everything happens in the
/// constructor). It does NOT do service location, routing or global state.
///
/// Patterns: Template Method (`dispose` orchestrates `onDispose` + bag).
/// Dependencies: `dart:core` + `kortex_disposable.dart` (pure).
library;

import 'kortex_disposable.dart';

/// Base class for controllers with deterministic disposal.
///
/// Initialization happens exclusively in the constructor (no magic `onInit`),
/// keeping it directly testable outside a `KortexScope`. Subclasses that
/// override [dispose] must call `super.dispose()`.
abstract class IKortexController implements IKortexDisposable {
  /// Integrated bag; every resource registered here is released on [dispose].
  final KortexDisposeBag disposeBag = KortexDisposeBag();

  /// Whether this controller has already been disposed.
  bool get isDisposed => disposeBag.isDisposed;

  /// Registers [item] in the [disposeBag] and returns it (constructor use).
  T autoDispose<T extends IKortexDisposable>(T item) => disposeBag.add(item);

  /// Optional hook invoked by [dispose], before the [disposeBag].
  void onDispose() {}

  /// Disposes this controller: [onDispose] first, then the [disposeBag].
  ///
  /// Idempotent and protected against re-execution.
  @override
  void dispose() {
    if (isDisposed) return;
    onDispose();
    disposeBag.dispose();
  }
}

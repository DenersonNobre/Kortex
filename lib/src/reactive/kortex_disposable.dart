/// Deterministic resource disposal (`IKortexDisposable`/`KortexDisposeBag`).
///
/// SRP: group disposables and cleanup callbacks, disposing them in reverse
/// (LIFO) order, idempotently. It does NOT do reactive tracking, widget
/// lifecycle management or dependency resolution.
///
/// Patterns: Composite + Guard Clause (early return when already disposed).
/// Dependencies: `dart:core` only (pure — no Flutter, no `BuildContext`).
library;

/// Explicit contract for deterministic resource release.
///
/// Implemented by reactive primitives, controllers and by any service or
/// data source that needs cleanup (the `KortexScope` disposes instances
/// implementing this contract automatically).
abstract interface class IKortexDisposable {
  /// Releases the held resources. Safe to call more than once.
  void dispose();
}

/// Aggregator of disposables with reverse-order (LIFO) disposal.
///
/// - `add` registers an [IKortexDisposable]; if the bag is already disposed,
///   the item is disposed immediately and returned unchanged to the caller.
/// - `addCallback` registers an arbitrary cleanup, following the same
///   post-disposal rule as `add`.
/// - `dispose` runs everything in reverse registration order and is idempotent.
class KortexDisposeBag implements IKortexDisposable {
  final List<void Function()> _cleanups = [];
  var _isDisposed = false;

  /// Whether the bag has already been disposed.
  bool get isDisposed => _isDisposed;

  /// Registers [item] for disposal on [dispose].
  ///
  /// Returns [item] itself to allow fluent usage. If the bag is already
  /// disposed, [item] is disposed immediately.
  T add<T extends IKortexDisposable>(T item) {
    if (_isDisposed) {
      item.dispose();
      return item;
    }
    _cleanups.add(item.dispose);
    return item;
  }

  /// Registers an arbitrary [onDispose] callback to run on [dispose].
  ///
  /// If the bag is already disposed, [onDispose] runs immediately.
  void addCallback(void Function() onDispose) {
    if (_isDisposed) {
      onDispose();
      return;
    }
    _cleanups.add(onDispose);
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    for (var i = _cleanups.length - 1; i >= 0; i--) {
      _cleanups[i]();
    }
    _cleanups.clear();
  }
}

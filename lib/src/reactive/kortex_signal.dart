/// Mutable signal with configurable equality (`KortexSignal`).
///
/// SRP: hold a value, compare it with `equals` and notify subscribers only
/// when it changes. It does NOT derive values (that is `KortexComputed`),
/// run effects (that is `KortexEffect`) or batch notifications (that is
/// `KortexTracker`).
///
/// Patterns: Observer (through `IKortexReactiveNode`) + Guard Clause.
/// Dependencies: `dart:core` + `kortex_observer.dart` (pure).
library;

import 'kortex_observer.dart';

/// Equality between the previous and the next value (`true` = unchanged).
typedef KortexEquals<T> = bool Function(T previous, T next);

/// Derives the next value from the current one (used by `update`).
typedef KortexUpdater<T> = T Function(T current);

bool _defaultEquals<T>(T previous, T next) => previous == next;

/// Read-only view of a signal (encapsulation boundary).
abstract interface class IKortexReadonlySignal<T>
    implements IKortexReactiveNode {
  /// Whether the signal has been disposed.
  bool get isDisposed;

  /// Current value, registering the read in the active `KortexTracker`.
  T get value;

  /// Current value without registering a read.
  T peek();
}

/// Mutable container with conditional notification and post-dispose blocking.
class KortexSignal<T> implements IKortexReadonlySignal<T> {
  /// Creates the signal with [initialValue] and an optional [equals]
  /// (defaults to `==`).
  KortexSignal(T initialValue, {KortexEquals<T>? equals})
    : _value = initialValue,
      _equals = equals ?? _defaultEquals;

  static const _disposedMessage = 'KortexSignal used after dispose()';

  T _value;
  final KortexEquals<T> _equals;
  final Set<IKortexObserver> _observers = {};
  var _isDisposed = false;

  @override
  bool get isDisposed => _isDisposed;

  @override
  T get value {
    _requireAlive();
    KortexTracker.recordRead(this);
    return _value;
  }

  @override
  T peek() {
    _requireAlive();
    return _value;
  }

  /// Replaces the value; no notification when [equals] approves it.
  set value(T next) {
    _requireAlive();
    if (_equals(_value, next)) return;
    _value = next;
    KortexTracker.notifyChange(this, _observers);
  }

  /// Applies [updater] to the current value in a single write.
  void update(KortexUpdater<T> updater) => value = updater(peek());

  /// Read-only view of this signal (same lifecycle).
  IKortexReadonlySignal<T> get readonly => this;

  @override
  void addObserver(IKortexObserver observer) {
    _observers.add(observer);
  }

  @override
  void removeObserver(IKortexObserver observer) {
    _observers.remove(observer);
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _observers.clear();
  }

  void _requireAlive() {
    if (_isDisposed) throw StateError(_disposedMessage);
  }
}

/// Ergonomic shortcut for `KortexSignal(...)`.
KortexSignal<T> kortexSignal<T>(T initialValue, {KortexEquals<T>? equals}) =>
    KortexSignal(initialValue, equals: equals);

/// Ergonomic `.kortex` shortcut for non-nullable objects (`0.kortex`,
/// `User().kortex`, `Status.idle.kortex`).
///
/// Restricted to `T extends Object` so `null.kortex` fails at compile time
/// (use `kortexSignal<T?>(null)` for nullable signals).
extension KortexSignalExtension<T extends Object> on T {
  /// Wraps this value in a new [KortexSignal].
  KortexSignal<T> get kortex => KortexSignal<T>(this);
}

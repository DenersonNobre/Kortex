/// Reactive mutable set (`KortexSet`) with read-only view encapsulation.
///
/// SRP: hold a `Set<E>`, track reads through `KortexTracker` and emit a single
/// notification per effective mutation (suppressing no-ops and batching bulk
/// operations). It does NOT render UI or depend on Flutter.
///
/// Patterns: Observer (through `IKortexReactiveNode`) + Guard Clause.
/// Dependencies: `dart:collection` + `kortex_observer.dart` + `kortex_signal.dart`.
library;

import 'dart:collection';

import 'kortex_observer.dart';
import 'kortex_signal.dart';

/// Read-only reactive view over a set (encapsulation boundary).
abstract interface class IKortexReadonlySet<E>
    implements IKortexReadonlySignal<Set<E>> {
  /// Number of elements, registering a read in the active `KortexTracker`.
  int get length;

  /// Whether the set has no elements, registering a read.
  bool get isEmpty;

  /// Whether the set has at least one element, registering a read.
  bool get isNotEmpty;

  /// Whether [element] is in the set, registering a read in `KortexTracker`.
  bool contains(Object? element);
}

/// Short alias for [IKortexReadonlySet].
typedef IKortexSet<E> = IKortexReadonlySet<E>;

/// Mutable reactive set with no-op suppression, batching and post-dispose guard.
class KortexSet<E> extends SetBase<E> implements IKortexReadonlySet<E> {
  /// Creates a reactive set copied from [initial].
  KortexSet([Iterable<E> initial = const []]) : _items = Set<E>.of(initial);

  static const _disposedMessage = 'KortexSet used after dispose()';

  final Set<E> _items;
  final Set<IKortexObserver> _observers = {};
  var _isDisposed = false;

  @override
  bool get isDisposed => _isDisposed;

  /// Read-only view of this set (same lifecycle).
  IKortexReadonlySet<E> get readonly => this;

  @override
  Set<E> get value {
    _requireAlive();
    KortexTracker.recordRead(this);
    return UnmodifiableSetView<E>(_items);
  }

  @override
  Set<E> peek() {
    _requireAlive();
    return UnmodifiableSetView<E>(_items);
  }

  @override
  bool add(E value) {
    _requireAlive();
    final added = _items.add(value);
    if (added) _notify();
    return added;
  }

  @override
  void addAll(Iterable<E> elements) {
    _requireAlive();
    final before = _items.length;
    _items.addAll(elements);
    if (_items.length != before) _notify();
  }

  @override
  bool contains(Object? element) {
    _requireAlive();
    KortexTracker.recordRead(this);
    return _items.contains(element);
  }

  @override
  Iterator<E> get iterator {
    _requireAlive();
    KortexTracker.recordRead(this);
    return _items.iterator;
  }

  @override
  int get length {
    _requireAlive();
    KortexTracker.recordRead(this);
    return _items.length;
  }

  @override
  bool get isEmpty => length == 0;

  @override
  bool get isNotEmpty => length > 0;

  @override
  E? lookup(Object? element) {
    _requireAlive();
    KortexTracker.recordRead(this);
    return _items.lookup(element);
  }

  @override
  bool remove(Object? value) {
    _requireAlive();
    final removed = _items.remove(value);
    if (removed) _notify();
    return removed;
  }

  @override
  void removeAll(Iterable<Object?> elements) {
    _requireAlive();
    final before = _items.length;
    _items.removeAll(elements);
    if (_items.length != before) _notify();
  }

  @override
  void retainAll(Iterable<Object?> elements) {
    _requireAlive();
    final before = _items.length;
    _items.retainAll(elements);
    if (_items.length != before) _notify();
  }

  @override
  void removeWhere(bool Function(E element) test) {
    _requireAlive();
    final before = _items.length;
    _items.removeWhere(test);
    if (_items.length != before) _notify();
  }

  @override
  void retainWhere(bool Function(E element) test) {
    _requireAlive();
    final before = _items.length;
    _items.retainWhere(test);
    if (_items.length != before) _notify();
  }

  @override
  void clear() {
    _requireAlive();
    if (_items.isEmpty) return;
    _items.clear();
    _notify();
  }

  @override
  Set<E> toSet() {
    _requireAlive();
    KortexTracker.recordRead(this);
    return Set<E>.of(_items);
  }

  /// Replaces all elements with [elements], suppressing notification if equal.
  void replaceAll(Iterable<E> elements) {
    _requireAlive();
    final next = Set<E>.of(elements);
    if (_setEquals(_items, next)) return;
    KortexTracker.batch(() {
      _items
        ..clear()
        ..addAll(next);
      _notify();
    });
  }

  @override
  void addObserver(IKortexObserver observer) => _observers.add(observer);

  @override
  void removeObserver(IKortexObserver observer) => _observers.remove(observer);

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _observers.clear();
    _items.clear();
  }

  void _notify() => KortexTracker.notifyChange(this, _observers);

  void _requireAlive() {
    if (_isDisposed) throw StateError(_disposedMessage);
  }

  static bool _setEquals<T>(Set<T> a, Set<T> b) =>
      a.length == b.length && a.containsAll(b);
}

/// Ergonomic shortcut for `KortexSet(...)`.
KortexSet<E> kortexSet<E>([Iterable<E> initial = const []]) =>
    KortexSet<E>(initial);

/// Ergonomic `.kortexSet` shortcut for creating a [KortexSet] from a [Set].
extension KortexSetExtension<E> on Set<E> {
  /// Creates a reactive [KortexSet] copied from this set.
  KortexSet<E> get kortexSet => KortexSet<E>(this);
}

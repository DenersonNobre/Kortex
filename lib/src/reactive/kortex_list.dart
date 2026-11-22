/// Reactive mutable list (`KortexList`) with read-only view encapsulation.
///
/// SRP: hold a `List<E>`, track reads through `KortexTracker` and emit a single
/// notification per effective mutation (suppressing no-ops and batching bulk
/// operations). It does NOT render UI or depend on Flutter.
///
/// Patterns: Observer (through `IKortexReactiveNode`) + Guard Clause.
/// Dependencies: `dart:collection` + `kortex_observer.dart` + `kortex_signal.dart`.
library;

import 'dart:collection';

import 'kortex_observer.dart';
import 'kortex_signal.dart';

/// Read-only reactive view over a list (encapsulation boundary).
abstract interface class IKortexReadonlyList<E>
    implements IKortexReadonlySignal<List<E>> {
  /// Number of elements, registering a read in the active `KortexTracker`.
  int get length;

  /// Whether the list has no elements, registering a read.
  bool get isEmpty;

  /// Whether the list has at least one element, registering a read.
  bool get isNotEmpty;

  /// Element at [index], registering a read in the active `KortexTracker`.
  E operator [](int index);
}

/// Mutable reactive list with no-op suppression, batching and post-dispose guard.
class KortexList<E> extends ListBase<E> implements IKortexReadonlyList<E> {
  /// Creates a reactive list copied from [initial].
  KortexList([Iterable<E> initial = const []]) : _items = List<E>.of(initial);

  static const _disposedMessage = 'KortexList used after dispose()';

  final List<E> _items;
  final Set<IKortexObserver> _observers = {};
  var _isDisposed = false;

  @override
  bool get isDisposed => _isDisposed;

  /// Read-only view of this list (same lifecycle).
  IKortexReadonlyList<E> get readonly => this;

  @override
  List<E> get value {
    _requireAlive();
    KortexTracker.recordRead(this);
    return UnmodifiableListView<E>(_items);
  }

  @override
  List<E> peek() {
    _requireAlive();
    return UnmodifiableListView<E>(_items);
  }

  @override
  int get length {
    _requireAlive();
    KortexTracker.recordRead(this);
    return _items.length;
  }

  @override
  set length(int newLength) {
    _requireAlive();
    if (newLength == _items.length) return;
    _items.length = newLength;
    _notify();
  }

  @override
  bool get isEmpty => length == 0;

  @override
  bool get isNotEmpty => length > 0;

  @override
  E operator [](int index) {
    _requireAlive();
    KortexTracker.recordRead(this);
    return _items[index];
  }

  @override
  void operator []=(int index, E value) {
    _requireAlive();
    if (_items[index] == value) return;
    _items[index] = value;
    _notify();
  }

  @override
  void add(E element) {
    _requireAlive();
    _items.add(element);
    _notify();
  }

  @override
  void addAll(Iterable<E> iterable) {
    _requireAlive();
    final before = _items.length;
    _items.addAll(iterable);
    if (_items.length != before) _notify();
  }

  @override
  void insert(int index, E element) {
    _requireAlive();
    _items.insert(index, element);
    _notify();
  }

  @override
  void insertAll(int index, Iterable<E> iterable) {
    _requireAlive();
    final before = _items.length;
    _items.insertAll(index, iterable);
    if (_items.length != before) _notify();
  }

  @override
  bool remove(Object? element) {
    _requireAlive();
    final removed = _items.remove(element);
    if (removed) _notify();
    return removed;
  }

  @override
  E removeAt(int index) {
    _requireAlive();
    final removed = _items.removeAt(index);
    _notify();
    return removed;
  }

  @override
  E removeLast() {
    _requireAlive();
    final removed = _items.removeLast();
    _notify();
    return removed;
  }

  @override
  void removeRange(int start, int end) {
    _requireAlive();
    final before = _items.length;
    _items.removeRange(start, end);
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
  void sort([int Function(E a, E b)? compare]) {
    _requireAlive();
    if (_items.length <= 1) return;
    _items.sort(compare);
    _notify();
  }

  /// Replaces all elements with [items], suppressing notification if unchanged.
  void replaceAll(Iterable<E> items) {
    _requireAlive();
    final next = List<E>.of(items);
    if (_listEquals(_items, next)) return;
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

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Ergonomic shortcut for `KortexList(...)`.
KortexList<E> kortexList<E>([Iterable<E> initial = const []]) =>
    KortexList<E>(initial);

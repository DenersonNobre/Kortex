/// Reactive mutable map (`KortexMap`) with read-only view encapsulation.
///
/// SRP: hold a `Map<K, V>`, track reads through `KortexTracker` and emit a single
/// notification per effective mutation (suppressing no-ops and batching bulk
/// operations). It does NOT render UI or depend on Flutter.
///
/// Patterns: Observer (through `IKortexReactiveNode`) + Guard Clause.
/// Dependencies: `dart:collection` + `kortex_observer.dart` + `kortex_signal.dart`.
library;

import 'dart:collection';

import 'kortex_observer.dart';
import 'kortex_signal.dart';

/// Read-only reactive view over a map (encapsulation boundary).
abstract interface class IKortexReadonlyMap<K, V>
    implements IKortexReadonlySignal<Map<K, V>> {
  /// Number of entries, registering a read in the active `KortexTracker`.
  int get length;

  /// Whether the map has no entries, registering a read.
  bool get isEmpty;

  /// Whether the map has at least one entry, registering a read.
  bool get isNotEmpty;

  /// Whether [key] exists in the map, registering a read.
  bool containsKey(Object? key);

  /// Value associated with [key], registering a read in `KortexTracker`.
  V? operator [](Object? key);
}

/// Mutable reactive map with no-op suppression, batching and post-dispose guard.
class KortexMap<K, V> extends MapBase<K, V>
    implements IKortexReadonlyMap<K, V> {
  /// Creates a reactive map copied from [initial].
  KortexMap([Map<K, V>? initial])
    : _entries = initial == null ? <K, V>{} : Map<K, V>.of(initial);

  static const _disposedMessage = 'KortexMap used after dispose()';

  final Map<K, V> _entries;
  final Set<IKortexObserver> _observers = {};
  var _isDisposed = false;

  @override
  bool get isDisposed => _isDisposed;

  /// Read-only view of this map (same lifecycle).
  IKortexReadonlyMap<K, V> get readonly => this;

  @override
  Map<K, V> get value {
    _requireAlive();
    KortexTracker.recordRead(this);
    return UnmodifiableMapView<K, V>(_entries);
  }

  @override
  Map<K, V> peek() {
    _requireAlive();
    return UnmodifiableMapView<K, V>(_entries);
  }

  @override
  V? operator [](Object? key) {
    _requireAlive();
    KortexTracker.recordRead(this);
    return _entries[key];
  }

  @override
  void operator []=(K key, V value) {
    _requireAlive();
    if (_entries.containsKey(key) && _entries[key] == value) return;
    _entries[key] = value;
    _notify();
  }

  @override
  Iterable<K> get keys {
    _requireAlive();
    KortexTracker.recordRead(this);
    return _entries.keys;
  }

  @override
  int get length {
    _requireAlive();
    KortexTracker.recordRead(this);
    return _entries.length;
  }

  @override
  bool get isEmpty => length == 0;

  @override
  bool get isNotEmpty => length > 0;

  @override
  bool containsKey(Object? key) {
    _requireAlive();
    KortexTracker.recordRead(this);
    return _entries.containsKey(key);
  }

  @override
  V? remove(Object? key) {
    _requireAlive();
    if (!_entries.containsKey(key)) return null;
    final removed = _entries.remove(key);
    _notify();
    return removed;
  }

  @override
  void clear() {
    _requireAlive();
    if (_entries.isEmpty) return;
    _entries.clear();
    _notify();
  }

  @override
  void addAll(Map<K, V> other) {
    _requireAlive();
    var changed = false;
    other.forEach((key, value) {
      if (!_entries.containsKey(key) || _entries[key] != value) {
        _entries[key] = value;
        changed = true;
      }
    });
    if (changed) _notify();
  }

  @override
  void addEntries(Iterable<MapEntry<K, V>> newEntries) {
    _requireAlive();
    var changed = false;
    for (final entry in newEntries) {
      if (!_entries.containsKey(entry.key) ||
          _entries[entry.key] != entry.value) {
        _entries[entry.key] = entry.value;
        changed = true;
      }
    }
    if (changed) _notify();
  }

  @override
  void removeWhere(bool Function(K key, V value) test) {
    _requireAlive();
    final before = _entries.length;
    _entries.removeWhere(test);
    if (_entries.length != before) _notify();
  }

  @override
  void updateAll(V Function(K key, V value) update) {
    _requireAlive();
    var changed = false;
    _entries.updateAll((key, current) {
      final next = update(key, current);
      if (next != current) changed = true;
      return next;
    });
    if (changed) _notify();
  }

  /// Replaces all entries with [next], suppressing notification if unchanged.
  void replaceAll(Map<K, V> next) {
    _requireAlive();
    if (_mapEquals(_entries, next)) return;
    KortexTracker.batch(() {
      _entries
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
    _entries.clear();
  }

  void _notify() => KortexTracker.notifyChange(this, _observers);

  void _requireAlive() {
    if (_isDisposed) throw StateError(_disposedMessage);
  }

  static bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (!b.containsKey(entry.key) || b[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }
}

/// Ergonomic shortcut for `KortexMap(...)`.
KortexMap<K, V> kortexMap<K, V>([Map<K, V>? initial]) =>
    KortexMap<K, V>(initial);

/// Ergonomic `.kortexMap` shortcut for creating a [KortexMap] from a [Map].
extension KortexMapExtension<K, V> on Map<K, V> {
  /// Creates a reactive [KortexMap] copied from this map.
  KortexMap<K, V> get kortexMap => KortexMap<K, V>(this);
}

/// Bidirectional bridges with Flutter's `Listenable`.
///
/// SRP: adapt `Listenable`/`ValueListenable` for reactive reads and expose
/// signals as `Listenable` (e.g. a router's `refreshListenable`), without
/// transferring ownership or lifecycle. It does NOT transform events.
///
/// Patterns: Adapter whose disposal only removes its own link.
/// Dependencies: `package:flutter/foundation.dart` + the reactive layer.
library;

import 'package:flutter/foundation.dart';

import '../reactive/reactive.dart';

/// Read-only view of a `Listenable` as a reactive signal.
///
/// `dispose` removes only the link (the original `Listenable` is preserved).
class KortexListenableSignal<T>
    implements IKortexReadonlySignal<T>, IKortexDisposable {
  KortexListenableSignal._(this._listenable, this._read);

  static const _disposedMessage = 'KortexListenableSignal used after dispose()';

  final Listenable _listenable;
  final T Function() _read;
  final Set<IKortexObserver> _observers = {};
  var _listening = false;
  var _isDisposed = false;

  @override
  bool get isDisposed => _isDisposed;

  @override
  T get value {
    _requireAlive();
    _ensureListening();
    KortexTracker.recordRead(this);
    return _read();
  }

  @override
  T peek() {
    _requireAlive();
    return _read();
  }

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
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    _listenable.removeListener(_onListenable);
    _observers.clear();
  }

  void _ensureListening() {
    if (_listening) {
      return;
    }
    _listening = true;
    _listenable.addListener(_onListenable);
  }

  void _onListenable() {
    KortexTracker.notifyChange(this, _observers);
  }

  void _requireAlive() {
    if (_isDisposed) {
      throw StateError(_disposedMessage);
    }
  }
}

/// Adapts a `ValueListenable` (`ValueNotifier`, `TextEditingController`).
extension KortexValueListenableSignal<T> on ValueListenable<T> {
  /// Exposes this observable as a read-only signal.
  KortexListenableSignal<T> toKortexSignal() =>
      KortexListenableSignal<T>._(this, () => value);
}

/// Adapts a `Listenable` (`ChangeNotifier`, `ScrollController`) with a read.
extension KortexListenableSignalWith on Listenable {
  /// Exposes this observable through [read] on every notification.
  KortexListenableSignal<T> toKortexSignalWith<T>(T Function() read) =>
      KortexListenableSignal<T>._(this, read);
}

/// Bridge observing a node and notifying `VoidCallback` listeners.
class _ListenableBridge implements IKortexObserver {
  _ListenableBridge(this._emit);

  final void Function(IKortexReactiveNode) _emit;

  @override
  void onRead(IKortexReactiveNode node) => _emit(node);
}

/// `Listenable` over a signal (e.g. a router's `refreshListenable`).
class KortexSignalListenable implements Listenable, IKortexDisposable {
  KortexSignalListenable._(this._node);

  static const _disposedMessage = 'KortexSignalListenable used after dispose()';

  final IKortexReactiveNode _node;
  final Set<VoidCallback> _listeners = {};
  late final IKortexObserver _bridge = _ListenableBridge(_emit);
  var _subscribed = false;
  var _isDisposed = false;

  @override
  void addListener(VoidCallback listener) {
    _requireAlive();
    _listeners.add(listener);
    _ensureSubscribed();
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
    if (_listeners.isEmpty) {
      _unsubscribe();
    }
  }

  @override
  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    _unsubscribe();
    _listeners.clear();
  }

  void _ensureSubscribed() {
    if (_subscribed) {
      return;
    }
    _subscribed = true;
    _node.addObserver(_bridge);
  }

  void _unsubscribe() {
    if (!_subscribed) {
      return;
    }
    _subscribed = false;
    _node.removeObserver(_bridge);
  }

  void _emit(IKortexReactiveNode node) {
    for (final listener in List.of(_listeners)) {
      listener();
    }
  }

  void _requireAlive() {
    if (_isDisposed) {
      throw StateError(_disposedMessage);
    }
  }
}

/// Exposes the signal as a `Listenable` (observes on demand of listeners).
extension KortexSignalToListenable<T> on IKortexReadonlySignal<T> {
  /// Opens the `Listenable` mirroring this signal.
  KortexSignalListenable toListenable() => KortexSignalListenable._(this);
}

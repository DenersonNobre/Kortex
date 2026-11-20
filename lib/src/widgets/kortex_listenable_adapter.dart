/// Pontes bidirecionais com `Listenable` do Flutter.
///
/// SRP: adaptar `Listenable`/`ValueListenable` para leitura reativa e expor
/// sinais como `Listenable` (ex.: `refreshListenable` do `go_router`), sem
/// transferir posse nem ciclo de vida. NÃO faz: transformar eventos.
///
/// Patterns: Adapter com descarte que só remove o próprio vínculo.
/// Dependências: `package:flutter/foundation.dart` + camada reativa.
library;

import 'package:flutter/foundation.dart';

import '../reactive/reactive.dart';

/// Visão somente-leitura de um `Listenable` como sinal reativo.
///
/// O `dispose` remove apenas o vínculo (preserva o `Listenable` original).
class KortexListenableSignal<T>
    implements IKortexReadonlySignal<T>, IKortexDisposable {
  KortexListenableSignal._(this._listenable, this._read);

  static const _disposedMessage = 'KortexListenableSignal usado após dispose()';

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

/// Adapta `ValueListenable` (`ValueNotifier`, `TextEditingController`).
extension KortexValueListenableSignal<T> on ValueListenable<T> {
  /// Expõe este observável como sinal somente-leitura.
  KortexListenableSignal<T> toKortexSignal() =>
      KortexListenableSignal<T>._(this, () => value);
}

/// Adapta `Listenable` (`ChangeNotifier`, `ScrollController`) com leitura.
extension KortexListenableSignalWith on Listenable {
  /// Expõe este observável via [read] a cada notificação.
  KortexListenableSignal<T> toKortexSignalWith<T>(T Function() read) =>
      KortexListenableSignal<T>._(this, read);
}

/// Ponte que observa um nó e avisa ouvintes `VoidCallback`.
class _ListenableBridge implements IKortexObserver {
  _ListenableBridge(this._emit);

  final void Function(IKortexReactiveNode) _emit;

  @override
  void onRead(IKortexReactiveNode node) => _emit(node);
}

/// `Listenable` sobre um sinal (ex.: `refreshListenable` de roteadores).
class KortexSignalListenable implements Listenable, IKortexDisposable {
  KortexSignalListenable._(this._node);

  static const _disposedMessage = 'KortexSignalListenable usado após dispose()';

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

/// Expõe o sinal como `Listenable` (observa sob demanda de ouvintes).
extension KortexSignalToListenable<T> on IKortexReadonlySignal<T> {
  /// Abre o `Listenable` espelhado neste sinal.
  KortexSignalListenable toListenable() => KortexSignalListenable._(this);
}

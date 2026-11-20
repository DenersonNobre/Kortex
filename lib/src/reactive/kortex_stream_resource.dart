/// Ponte reativa para `Stream` com cancelamento automático.
///
/// SRP: espelhar um `Stream<T>` em `IKortexAsyncState` e expor sinais como
/// `Stream<T>`, cancelando/removendo assinaturas no `dispose`/`cancel`.
/// NÃO faz: transformar eventos, bufferizar nem repetir último valor.
///
/// Patterns: Adapter (stream ↔ sinal) + Geração monotônica no `restart`.
/// Dependências: `dart:async`, `dart:core` + camada reativa (puro).
library;

import 'dart:async';

import 'kortex_disposable.dart';
import 'kortex_observer.dart';
import 'kortex_resource.dart';
import 'kortex_signal.dart';

/// Fábrica que abre o stream observado pelo recurso.
typedef KortexStreamFactory<T> = Stream<T> Function();

/// Recurso que espelha um `Stream<T>` em `IKortexAsyncState`.
///
/// `restart()` cancela a assinatura anterior e recaptura a fábrica
/// preservando o valor atual como `previousValue`.
class KortexStreamResource<T> implements IKortexDisposable {
  /// Cria o recurso; com [immediate] assina a fábrica no construtor.
  KortexStreamResource(
    KortexStreamFactory<T> streamFactory, {
    bool immediate = true,
  })  : _factory = streamFactory,
        _state = KortexSignal<IKortexAsyncState<T>>(
          KortexAsyncLoading<T>(),
        ) {
    if (immediate) {
      restart();
    }
  }

  static const _disposedMessage = 'KortexStreamResource usado após dispose()';

  final KortexStreamFactory<T> _factory;
  final KortexSignal<IKortexAsyncState<T>> _state;
  StreamSubscription<T>? _subscription;
  var _listenId = 0;
  var _isDisposed = false;

  /// Indica se o recurso foi descartado.
  bool get isDisposed => _isDisposed;

  /// Sinal somente-leitura do estado atual.
  IKortexReadonlySignal<IKortexAsyncState<T>> get state => _state.readonly;

  /// Cancela a assinatura atual e recaptura a fábrica.
  void restart() {
    _requireAlive();
    final id = ++_listenId;
    _cancelSubscription();
    _publishLoading();
    _subscribe(id);
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _listenId++;
    _cancelSubscription();
    _state.dispose();
  }

  void _publishLoading() {
    final previous = _state.peek().valueOrNull;
    _state.value = KortexAsyncLoading<T>(previousValue: previous);
  }

  void _subscribe(int id) {
    try {
      _subscription = _factory().listen(
        (value) => _onData(id, value),
        onError: (Object error, StackTrace stack) =>
            _onError(id, error, stack),
        cancelOnError: false,
      );
    } catch (error, stackTrace) {
      _publishIfCurrent(id, KortexAsyncError<T>(error, stackTrace));
    }
  }

  void _onData(int id, T value) {
    _publishIfCurrent(id, KortexAsyncData<T>(value));
  }

  void _onError(int id, Object error, StackTrace stackTrace) {
    _publishIfCurrent(id, KortexAsyncError<T>(error, stackTrace));
  }

  void _publishIfCurrent(int id, IKortexAsyncState<T> next) {
    if (!_isCurrent(id)) return;
    _state.value = next;
  }

  bool _isCurrent(int id) => !_isDisposed && id == _listenId;

  void _cancelSubscription() {
    final subscription = _subscription;
    _subscription = null;
    if (subscription == null) return;
    unawaited(subscription.cancel());
  }

  void _requireAlive() {
    if (_isDisposed) throw StateError(_disposedMessage);
  }
}

/// Ponte que entrega mudanças do sinal num `StreamController`.
class _SignalBridge<T> implements IKortexObserver {
  _SignalBridge(this._read, this._emit);

  final T Function() _read;
  final void Function(T) _emit;

  @override
  void onRead(IKortexReactiveNode node) => _emit(_read());
}

/// Abertura preguiçosa do stream de um sinal (anexa no `listen`).
class _SignalStream<T> {
  _SignalStream(this._node);

  final IKortexReadonlySignal<T> _node;
  StreamController<T>? _controller;
  _SignalBridge<T>? _bridge;

  Stream<T> open() {
    _controller = StreamController<T>(
      onListen: _attach,
      onCancel: _detach,
    );
    return _controller!.stream;
  }

  void _attach() {
    final controller = _controller;
    if (controller == null) return;
    final bridge = _SignalBridge<T>(_read, controller.add);
    _bridge = bridge;
    _node.addObserver(bridge);
  }

  T _read() => _node.value;

  void _detach() {
    final bridge = _bridge;
    _bridge = null;
    if (bridge == null) return;
    _node.removeObserver(bridge);
  }
}

/// Ponte de leitura: emite mudanças reativas como `Stream<T>`.
///
/// A observação começa no `listen` e é removida no `cancel`.
extension KortexSignalToStream<T> on IKortexReadonlySignal<T> {
  /// Abre o stream das mudanças deste sinal.
  Stream<T> toStream() => _SignalStream<T>(this).open();
}

/// Atalho ergonômico para `KortexStreamResource(...)`.
KortexStreamResource<T> kortexStreamResource<T>(
  KortexStreamFactory<T> streamFactory, {
  bool immediate = true,
}) =>
    KortexStreamResource(streamFactory, immediate: immediate);

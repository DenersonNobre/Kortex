/// Reactive bridge to `Stream` with automatic cancellation.
///
/// SRP: mirror a `Stream<T>` into an `IKortexAsyncState` and expose signals
/// as `Stream<T>`, cancelling/removing subscriptions on `dispose`/`cancel`.
/// It does NOT transform events, buffer them nor replay the last value.
///
/// Patterns: Adapter (stream ↔ signal) + monotonic generation on `restart`.
/// Dependencies: `dart:async`, `dart:core` + the reactive layer (pure).
library;

import 'dart:async';

import 'kortex_disposable.dart';
import 'kortex_observer.dart';
import 'kortex_resource.dart';
import 'kortex_signal.dart';

/// Factory opening the stream observed by the resource.
typedef KortexStreamFactory<T> = Stream<T> Function();

/// Resource mirroring a `Stream<T>` into an `IKortexAsyncState`.
///
/// `restart()` cancels the previous subscription and recaptures the factory,
/// preserving the current value as `previousValue`.
class KortexStreamResource<T> implements IKortexDisposable {
  /// Creates the resource; with [immediate] it subscribes in the constructor.
  KortexStreamResource(
    KortexStreamFactory<T> streamFactory, {
    bool immediate = true,
  }) : _factory = streamFactory,
       _state = KortexSignal<IKortexAsyncState<T>>(KortexAsyncLoading<T>()) {
    if (immediate) {
      restart();
    }
  }

  static const _disposedMessage = 'KortexStreamResource used after dispose()';

  final KortexStreamFactory<T> _factory;
  final KortexSignal<IKortexAsyncState<T>> _state;
  StreamSubscription<T>? _subscription;
  var _listenId = 0;
  var _isDisposed = false;

  /// Whether the resource has been disposed.
  bool get isDisposed => _isDisposed;

  /// Read-only signal of the current state.
  IKortexReadonlySignal<IKortexAsyncState<T>> get state => _state.readonly;

  /// Cancels the current subscription and recaptures the factory.
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
        onError: (Object error, StackTrace stack) => _onError(id, error, stack),
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

/// Bridge delivering signal changes to a `StreamController`.
class _SignalBridge<T> implements IKortexObserver {
  _SignalBridge(this._read, this._emit);

  final T Function() _read;
  final void Function(T) _emit;

  @override
  void onRead(IKortexReactiveNode node) => _emit(_read());
}

/// Lazy stream opening for a signal (attaches on `listen`).
class _SignalStream<T> {
  _SignalStream(this._node);

  final IKortexReadonlySignal<T> _node;
  StreamController<T>? _controller;
  _SignalBridge<T>? _bridge;

  Stream<T> open() {
    _controller = StreamController<T>(onListen: _attach, onCancel: _detach);
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

/// Read bridge: emits reactive changes as a `Stream<T>`.
///
/// Observation starts on `listen` and is removed on `cancel`.
extension KortexSignalToStream<T> on IKortexReadonlySignal<T> {
  /// Opens the stream of changes of this signal.
  Stream<T> toStream() => _SignalStream<T>(this).open();
}

/// Ergonomic shortcut for `KortexStreamResource(...)`.
KortexStreamResource<T> kortexStreamResource<T>(
  KortexStreamFactory<T> streamFactory, {
  bool immediate = true,
}) => KortexStreamResource(streamFactory, immediate: immediate);

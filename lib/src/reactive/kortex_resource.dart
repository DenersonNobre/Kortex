/// Async resource with `previousValue` and stale-result disposal.
///
/// SRP: represent an async load as an `IKortexAsyncState` signal, keeping
/// the last value across `refresh()` and ignoring conclusions superseded by a
/// newer `refresh()` or by `dispose()`. It does NOT do retry, TTL caching or
/// pagination (higher layers).
///
/// Patterns: Monotonic generation (`_loadId`) for silent disposal.
/// Dependencies: `dart:async`, `dart:core` + the reactive layer (pure).
library;

import 'dart:async';

import 'kortex_disposable.dart';
import 'kortex_signal.dart';

/// Loader producing the async value of the resource.
typedef KortexAsyncLoader<T> = Future<T> Function();

/// Sealed state of an async load (exhaustive pattern matching).
sealed class IKortexAsyncState<T> {
  /// Sealed base (only `Loading`, `Data` and `Error` extend it).
  const IKortexAsyncState();

  /// True while in `KortexAsyncLoading`.
  bool get isLoading => this is KortexAsyncLoading<T>;

  /// `Loading` with the previous value preserved (a refresh, not a first load).
  bool get isRefreshing {
    final self = this;
    return self is KortexAsyncLoading<T> && self.previousValue != null;
  }

  /// Available value (`Data` or `previousValue`), or `null`.
  T? get valueOrNull => switch (this) {
    KortexAsyncData(value: final value) => value,
    KortexAsyncLoading(previousValue: final previous) => previous,
    KortexAsyncError() => null,
  };
}

/// Load in progress, with the last known value (when there is one).
final class KortexAsyncLoading<T> extends IKortexAsyncState<T> {
  /// Creates the loading state with an optional [previousValue].
  const KortexAsyncLoading({this.previousValue});

  /// Last known value before this load.
  final T? previousValue;
}

/// Load completed with [value].
final class KortexAsyncData<T> extends IKortexAsyncState<T> {
  /// Creates the data state with [value].
  const KortexAsyncData(this.value);

  /// Loaded value.
  final T value;
}

/// Load failed with [error] (and an optional [stackTrace]).
final class KortexAsyncError<T> extends IKortexAsyncState<T> {
  /// Creates the error state with [error] and an optional [stackTrace].
  const KortexAsyncError(this.error, [this.stackTrace]);

  /// Failure captured from the loader.
  final Object error;

  /// Stack trace of the failure, when available.
  final StackTrace? stackTrace;
}

/// Async read controller with race-condition protection: only the most
/// recent load publishes; stale ones are discarded.
class KortexResource<T> implements IKortexDisposable {
  /// Creates the resource; with [immediate] the first load starts in the
  /// constructor.
  KortexResource(KortexAsyncLoader<T> loader, {bool immediate = true})
    : _loader = loader,
      _state = KortexSignal<IKortexAsyncState<T>>(KortexAsyncLoading<T>()) {
    if (immediate) {
      unawaited(refresh());
    }
  }

  static const _disposedMessage = 'KortexResource used after dispose()';

  final KortexAsyncLoader<T> _loader;
  final KortexSignal<IKortexAsyncState<T>> _state;
  var _loadId = 0;
  var _isDisposed = false;

  /// Whether the resource has been disposed.
  bool get isDisposed => _isDisposed;

  /// Read-only signal of the current state.
  IKortexReadonlySignal<IKortexAsyncState<T>> get state => _state.readonly;

  /// Starts a load, preserving the previous value; stale results are dropped.
  Future<void> refresh() {
    _requireAlive();
    final id = ++_loadId;
    _publishLoading();
    return _load(id);
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _loadId++;
    _state.dispose();
  }

  void _publishLoading() {
    final previous = _state.peek().valueOrNull;
    _state.value = KortexAsyncLoading<T>(previousValue: previous);
  }

  Future<void> _load(int id) async {
    try {
      final value = await _loader();
      _publishIfCurrent(id, KortexAsyncData<T>(value));
    } catch (error, stackTrace) {
      _publishIfCurrent(id, KortexAsyncError<T>(error, stackTrace));
    }
  }

  void _publishIfCurrent(int id, IKortexAsyncState<T> next) {
    if (!_isCurrent(id)) return;
    _state.value = next;
  }

  bool _isCurrent(int id) => !_isDisposed && id == _loadId;

  void _requireAlive() {
    if (_isDisposed) throw StateError(_disposedMessage);
  }
}

/// Ergonomic shortcut for `KortexResource(...)`.
KortexResource<T> kortexResource<T>(
  KortexAsyncLoader<T> loader, {
  bool immediate = true,
}) => KortexResource(loader, immediate: immediate);

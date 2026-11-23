/// Async command with a re-entrancy lock (`KortexCommand`).
///
/// SRP: run an async action/mutation exposing `isExecuting` and the reactive
/// state, ignoring concurrent triggers. It does NOT queue intents, debounce
/// between calls nor retry.
///
/// Patterns: Guard Clause (lock) + fire-and-remember of the late result.
/// Dependencies: `dart:async`, `dart:core` + the reactive layer (pure).
library;

import 'dart:async';

import 'kortex_disposable.dart';
import 'kortex_resource.dart';
import 'kortex_signal.dart';

/// Action executed by the command with the received parameter.
typedef KortexCommandAction<TParam, TResult> = Future<TResult> Function(
  TParam param,
);

/// Async mutation wrapper with a double-trigger lock.
///
/// A concurrent `execute` (while `isExecuting == true`) returns `null`
/// without starting a new run. Conclusions after `dispose` are discarded.
class KortexCommand<TParam, TResult> implements IKortexDisposable {
  /// Creates the command at rest (`isExecuting == false`, `state == null`).
  KortexCommand(KortexCommandAction<TParam, TResult> action)
    : _action = action,
      _isExecuting = KortexSignal<bool>(false),
      _state = KortexSignal<IKortexAsyncState<TResult>?>(null);

  static const _disposedMessage = 'KortexCommand used after dispose()';

  final KortexCommandAction<TParam, TResult> _action;
  final KortexSignal<bool> _isExecuting;
  final KortexSignal<IKortexAsyncState<TResult>?> _state;
  var _isDisposed = false;

  /// Whether the command has been disposed.
  bool get isDisposed => _isDisposed;

  /// Reactive signal of the run in progress.
  IKortexReadonlySignal<bool> get isExecuting => _isExecuting.readonly;

  /// Last result (`Data`/`Error`) or `null` before the first run.
  IKortexReadonlySignal<IKortexAsyncState<TResult>?> get state =>
      _state.readonly;

  /// Executes [param]; a concurrent call returns `null` without re-triggering.
  Future<TResult?> execute(TParam param) {
    _requireAlive();
    if (_isExecuting.peek()) return Future.value();
    _isExecuting.value = true;
    return _run(param);
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _isExecuting.dispose();
    _state.dispose();
  }

  Future<TResult?> _run(TParam param) async {
    try {
      final result = await _action(param);
      _publishIfAlive(KortexAsyncData<TResult>(result));
      return result;
    } catch (error, stackTrace) {
      _publishIfAlive(KortexAsyncError<TResult>(error, stackTrace));
      return null;
    } finally {
      _unflagIfAlive();
    }
  }

  void _publishIfAlive(IKortexAsyncState<TResult> next) {
    if (_isDisposed) return;
    _state.value = next;
  }

  void _unflagIfAlive() {
    if (_isDisposed) return;
    _isExecuting.value = false;
  }

  void _requireAlive() {
    if (_isDisposed) throw StateError(_disposedMessage);
  }
}

/// Ergonomic shortcut for `KortexCommand(...)`.
KortexCommand<TParam, TResult> kortexCommand<TParam, TResult>(
  KortexCommandAction<TParam, TResult> action,
) => KortexCommand(action);

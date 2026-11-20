/// Comando assíncrono com trava contra reentrância (`KortexCommand`).
///
/// SRP: executar uma ação/mutação assíncrona expondo `isExecuting` e o
/// estado reativo, ignorando disparos concorrentes. NÃO faz: fila de
/// intenções, debounce entre chamadas nem retry.
///
/// Patterns: Guard Clause (trava) + Fire-and-remember do resultado tardio.
/// Dependências: `dart:async`, `dart:core` + camada reativa (puro).
library;

import 'dart:async';

import 'kortex_disposable.dart';
import 'kortex_resource.dart';
import 'kortex_signal.dart';

/// Ação executada pelo comando com o parâmetro recebido.
typedef KortexCommandAction<TParam, TResult> = Future<TResult> Function(
  TParam param,
);

/// Encapsulador de mutação assíncrona com trava de duplo disparo.
///
/// `execute` concorrente (com `isExecuting == true`) retorna `null` sem
/// iniciar nova execução. Conclusões pós-`dispose` são descartadas.
class KortexCommand<TParam, TResult> implements IKortexDisposable {
  /// Cria o comando em repouso (`isExecuting == false`, `state == null`).
  KortexCommand(KortexCommandAction<TParam, TResult> action)
    : _action = action,
      _isExecuting = KortexSignal<bool>(false),
      _state = KortexSignal<IKortexAsyncState<TResult>?>(null);

  static const _disposedMessage = 'KortexCommand usado após dispose()';

  final KortexCommandAction<TParam, TResult> _action;
  final KortexSignal<bool> _isExecuting;
  final KortexSignal<IKortexAsyncState<TResult>?> _state;
  var _isDisposed = false;

  /// Indica se o comando foi descartado.
  bool get isDisposed => _isDisposed;

  /// Sinal reativo da execução em curso.
  IKortexReadonlySignal<bool> get isExecuting => _isExecuting.readonly;

  /// Último resultado (`Data`/`Error`) ou `null` antes da 1a execução.
  IKortexReadonlySignal<IKortexAsyncState<TResult>?> get state =>
      _state.readonly;

  /// Executa [param]; concorrente retorna `null` sem re-disparar.
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

/// Atalho ergonômico para `KortexCommand(...)`.
KortexCommand<TParam, TResult> kortexCommand<TParam, TResult>(
  KortexCommandAction<TParam, TResult> action,
) => KortexCommand(action);

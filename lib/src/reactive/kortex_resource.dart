/// Recurso assíncrono com `previousValue` e descarte de tardias.
///
/// SRP: representar carga assíncrona como sinal de `IKortexAsyncState`,
/// preservando o último valor em `refresh()` e ignorando conclusões
/// superadas por novo `refresh()` ou `dispose()`. NÃO faz: retry, cache
/// com TTL nem paginação (camadas acima).
///
/// Patterns: Geração monotônica (`_loadId`) para descarte silencioso.
/// Dependências: `dart:async`, `dart:core` + camada reativa (puro).
library;

import 'dart:async';

import 'kortex_disposable.dart';
import 'kortex_signal.dart';

/// Carregador que produz o valor assíncrono do recurso.
typedef KortexAsyncLoader<T> = Future<T> Function();

/// Estado selado de uma carga assíncrona (pattern matching exaustivo).
sealed class IKortexAsyncState<T> {
  /// Base selada (só `Loading`, `Data` e `Error` estendem).
  const IKortexAsyncState();

  /// Verdadeiro durante `KortexAsyncLoading`.
  bool get isLoading => this is KortexAsyncLoading<T>;

  /// `Loading` com valor anterior preservado (atualização, não 1a carga).
  bool get isRefreshing {
    final self = this;
    return self is KortexAsyncLoading<T> && self.previousValue != null;
  }

  /// Valor disponível (`Data` ou `previousValue`), ou `null`.
  T? get valueOrNull => switch (this) {
        KortexAsyncData(value: final value) => value,
        KortexAsyncLoading(previousValue: final previous) => previous,
        KortexAsyncError() => null,
      };
}

/// Carga em andamento, com o último valor conhecido (se houver).
final class KortexAsyncLoading<T> extends IKortexAsyncState<T> {
  /// Cria o estado de carga com [previousValue] opcional.
  const KortexAsyncLoading({this.previousValue});

  /// Último valor conhecido antes deste carregamento.
  final T? previousValue;
}

/// Carga concluída com [value].
final class KortexAsyncData<T> extends IKortexAsyncState<T> {
  /// Cria o estado de dados com [value].
  const KortexAsyncData(this.value);

  /// Valor carregado.
  final T value;
}

/// Carga falha com [error] (e [stackTrace] opcional).
final class KortexAsyncError<T> extends IKortexAsyncState<T> {
  /// Cria o estado de erro com [error] e [stackTrace] opcional.
  const KortexAsyncError(this.error, [this.stackTrace]);

  /// Falha capturada do carregador.
  final Object error;

  /// Rastro da falha, quando disponível.
  final StackTrace? stackTrace;
}

/// Controlador de leitura assíncrona com proteção contra condição de
/// corrida: só a carga mais recente publica; tardias são descartadas.
class KortexResource<T> implements IKortexDisposable {
  /// Cria o recurso; com [immediate] dispara a 1a carga no construtor.
  KortexResource(KortexAsyncLoader<T> loader, {bool immediate = true})
      : _loader = loader,
        _state = KortexSignal<IKortexAsyncState<T>>(
          KortexAsyncLoading<T>(),
        ) {
    if (immediate) {
      unawaited(refresh());
    }
  }

  static const _disposedMessage = 'KortexResource usado após dispose()';

  final KortexAsyncLoader<T> _loader;
  final KortexSignal<IKortexAsyncState<T>> _state;
  var _loadId = 0;
  var _isDisposed = false;

  /// Indica se o recurso foi descartado.
  bool get isDisposed => _isDisposed;

  /// Sinal somente-leitura do estado atual.
  IKortexReadonlySignal<IKortexAsyncState<T>> get state => _state.readonly;

  /// Inicia uma carga preservando o valor anterior; tardias caem fora.
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

/// Atalho ergonômico para `KortexResource(...)`.
KortexResource<T> kortexResource<T>(
  KortexAsyncLoader<T> loader, {
  bool immediate = true,
}) =>
    KortexResource(loader, immediate: immediate);

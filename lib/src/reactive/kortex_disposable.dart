/// Descarte determinístico de recursos (`IKortexDisposable`/`KortexDisposeBag`).
///
/// SRP: agrupar descartáveis e callbacks de limpeza com descarte em ordem
/// reversa (LIFO) e idempotente. NÃO faz: rastreamento reativo, gerenciamento
/// de ciclo de vida de widgets ou resolução de dependências.
///
/// Patterns: Composite + Guard Clause (saída imediata se já descartado).
/// Dependências: apenas `dart:core` (puro — sem Flutter, sem `BuildContext`).
library;

/// Contrato explícito de liberação determinística de recursos.
///
/// Implementado por primitivas reativas, controllers e por qualquer
/// serviço/datasource que precise de limpeza (o `KortexScope` descarta
/// automaticamente instâncias que implementam este contrato).
abstract interface class IKortexDisposable {
  /// Libera os recursos detidos. Deve ser seguro chamar mais de uma vez.
  void dispose();
}

/// Agregador de descartáveis com descarte em ordem reversa (LIFO).
///
/// - `add` registra um [IKortexDisposable]; se o bag já estiver descartado,
///   o item é descartado imediatamente e devolvido intacto ao chamador.
/// - `addCallback` registra uma limpeza arbitrária, com a mesma regra
///   pós-descarte do `add`.
/// - `dispose` executa tudo em ordem reversa de registro e é idempotente.
class KortexDisposeBag implements IKortexDisposable {
  final List<void Function()> _cleanups = [];
  var _isDisposed = false;

  /// Indica se o bag já foi descartado.
  bool get isDisposed => _isDisposed;

  /// Registra [item] para descarte em [dispose].
  ///
  /// Retorna o próprio [item] para permitir uso fluente. Se o bag já
  /// estiver descartado, [item] é descartado imediatamente.
  T add<T extends IKortexDisposable>(T item) {
    if (_isDisposed) {
      item.dispose();
      return item;
    }
    _cleanups.add(item.dispose);
    return item;
  }

  /// Registra um [onDispose] arbitrário para executar em [dispose].
  ///
  /// Se o bag já estiver descartado, [onDispose] executa imediatamente.
  void addCallback(void Function() onDispose) {
    if (_isDisposed) {
      onDispose();
      return;
    }
    _cleanups.add(onDispose);
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    for (var i = _cleanups.length - 1; i >= 0; i--) {
      _cleanups[i]();
    }
    _cleanups.clear();
  }
}

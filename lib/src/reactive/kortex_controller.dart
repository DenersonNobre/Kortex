/// Controlador base com ciclo de vida explícito (`IKortexController`).
///
/// SRP: oferecer `KortexDisposeBag` integrado e gancho `onDispose()` para
/// controllers, sem mágica de inicialização (tudo ocorre no construtor).
/// NÃO faz: localização de serviços, roteamento ou estado global.
///
/// Patterns: Template Method (`dispose` orquestra `onDispose` + bag).
/// Dependências: apenas `dart:core` + `kortex_disposable.dart` (puro).
library;

import 'kortex_disposable.dart';

/// Base para controllers com descarte determinístico.
///
/// A inicialização ocorre exclusivamente no construtor (sem `onInit` mágico),
/// mantendo testabilidade direta fora do `KortexScope`. Subclasses que
/// sobrescreverem [dispose] devem chamar `super.dispose()`.
abstract class IKortexController implements IKortexDisposable {
  /// Bag integrado; todo recurso registrado aqui cai no [dispose].
  final KortexDisposeBag disposeBag = KortexDisposeBag();

  /// Indica se este controller já foi descartado.
  bool get isDisposed => disposeBag.isDisposed;

  /// Registra [item] no [disposeBag] e o devolve (uso no construtor).
  T autoDispose<T extends IKortexDisposable>(T item) => disposeBag.add(item);

  /// Gancho opcional executado em [dispose], antes do [disposeBag].
  void onDispose() {}

  /// Descarta este controller: [onDispose] e depois o [disposeBag].
  ///
  /// Idempotente e protegido contra reexecução.
  @override
  void dispose() {
    if (isDisposed) return;
    onDispose();
    disposeBag.dispose();
  }
}

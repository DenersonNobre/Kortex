/// Provedor imutável de dependências (`KortexProvider` + leitor de escopo).
///
/// SRP: descrever COMO criar/descartar um `T` (fábrica, descarte opcional,
/// `lazy` ou valor externo). NÃO faz: armazenar instâncias, resolver a
/// árvore nem notificar widgets (papel do `KortexScope`).
///
/// Patterns: Factory Method (via `create`) + Explicit Dispose.
/// Dependências: `dart:core` + `IKortexDisposable` (puro, sem Flutter).
///
/// Os nomes dos parâmetros seguem o contrato da SPEC e diferem dos campos
/// internos — por isso este arquivo não usa formais inicializadores.
// ignore_for_file: prefer_initializing_formals
library;

import '../reactive/reactive.dart';

/// Leitor explícito para resolver irmãos dentro de `KortexProvider.create`.
abstract interface class IKortexScopeReader {
  /// Resolve [T] entre irmãos do escopo ou nos ancestrais.
  T read<T>();
}

/// Fábrica que cria [T] recebendo apenas o leitor do escopo.
typedef KortexCreate<T> = T Function(IKortexScopeReader scope);

/// Descarte explícito de uma instância criada pelo provider.
typedef KortexDispose<T> = void Function(T instance);

/// Definição imutável de criação (`create`), `lazy`, `.value` e `dispose`.
class KortexProvider<T> {
  /// Provider com criação sob demanda; `dispose` opcional e explícito.
  KortexProvider({
    required KortexCreate<T> create,
    KortexDispose<T>? dispose,
    bool lazy = false,
  }) : _create = create,
       _dispose = dispose,
       isLazy = lazy,
       _value = null,
       isValue = false;

  /// Provider de valor externo: sem criação e sem descarte pelo escopo.
  KortexProvider.value({required T value})
    : _create = _noFactory,
      _dispose = null,
      isLazy = false,
      _value = value,
      isValue = true;

  static const _valueHasNoFactory = 'KortexProvider.value não cria instâncias.';

  static Never _noFactory(IKortexScopeReader _) =>
      throw StateError(_valueHasNoFactory);

  final KortexCreate<T> _create;
  final KortexDispose<T>? _dispose;

  /// Verdadeiro quando a criação ocorre só no primeiro `read`.
  final bool isLazy;

  /// Verdadeiro para `KortexProvider.value` (posse externa).
  final bool isValue;
  final T? _value;

  /// Token de tipo usado como chave no `KortexScope`.
  Type get type => T;

  /// Valor externo (válido apenas para `.value`).
  T get value => _value as T;

  /// Cria a instância via `create` (`.value` lança via sentinela).
  T createInstance(IKortexScopeReader reader) => _create(reader);

  /// Descarta [instance]: callback explícito ou `IKortexDisposable`.
  ///
  /// Instâncias `.value` nunca são descartadas pelo escopo.
  void disposeInstance(T instance) {
    if (isValue) {
      return;
    }
    final dispose = _dispose;
    if (dispose != null) {
      dispose(instance);
      return;
    }
    if (instance is IKortexDisposable) {
      instance.dispose();
    }
  }
}

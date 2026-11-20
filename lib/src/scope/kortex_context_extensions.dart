/// Extensões de `BuildContext` para resolução no `KortexScope`.
///
/// SRP: expor `read` (sem assinatura) e `watch` (com reconstrução) como
/// sintaxe de contexto. NÃO faz: resolução fora de `KortexScope` — sem
/// escopo ancestral, lança `StateError`.
///
/// Dependências: `package:flutter/widgets.dart` + `kortex_scope.dart`.
library;

import 'package:flutter/widgets.dart';

import 'kortex_scope.dart';

/// Leitura de dependências do `KortexScope` via `BuildContext`.
extension KortexContextReader on BuildContext {
  /// Resolve [T] sem assinar o escopo (não reconstrói em atualizações).
  T readKortex<T>() =>
      KortexScope.resolveKortexDependency<T>(this, listen: false);

  /// Resolve [T] assinando os escopos (reconstrói quando atualizarem).
  T watchKortex<T>() =>
      KortexScope.resolveKortexDependency<T>(this, listen: true);
}

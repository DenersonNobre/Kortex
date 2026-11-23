// Mutex assíncrono que serializa seções críticas: [run] enfileira a ação
// após as anteriores e espera a fila esvaziar. Exceção numa ação não bloqueia
// as seguintes.
//
// Atribuição: **mutex/lock — concorrência** (origem nos sistemas operacionais/
// linguagens concorrentes) — fora dos 23 GoF.

import 'dart:async';

/// Serializa seções críticas assíncronas: [run] enfileira a ação após as
/// anteriores e espera a fila esvaziar. Exceção numa ação não bloqueia as
/// seguintes.
class AsyncLock {
  Future<void> _ultima = Future<void>.value();

  /// Enfileira [acao] após as anteriores e a resolve quando concluída — mesmo
  /// que [acao] lance (a fila nunca fica presa).
  Future<T> run<T>(Future<T> Function() acao) {
    final anterior = _ultima;
    final completa = Completer<void>();
    _ultima = completa.future;
    return anterior.then((_) => acao()).whenComplete(completa.complete);
  }
}

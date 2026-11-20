/// Controller do contador do exemplo mínimo.
///
/// SRP: expor contador reativo e salvamento com trava de reentrância.
/// NÃO faz: UI, roteamento ou persistência real.
///
/// Patterns: `IKortexController` com inicialização no construtor.
/// Dependências: `kortex` (puro + escopo) e `dart:async` via `Future`.
library;

import 'package:kortex/kortex.dart';

/// Contador com salvamento assíncrono simulado.
class CounterController extends IKortexController {
  /// Registra sinal e comando no `disposeBag` (descarte automático).
  CounterController() {
    autoDispose(count);
    save = autoDispose(
      KortexCommand<void, int>((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        return count.value;
      }),
    );
  }

  /// Contador (leitura reativa, escrita encapsulada).
  final KortexSignal<int> count = KortexSignal(0);

  /// Salvamento com `isExecuting` e trava de duplo clique.
  late final KortexCommand<void, int> save;

  /// Incrementa o contador.
  void increment() => count.update((value) => value + 1);

  /// Decrementa o contador.
  void decrement() => count.update((value) => value - 1);
}

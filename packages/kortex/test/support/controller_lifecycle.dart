/// Gate de ciclo de vida dos controllers criados nos testes do pacote.
///
/// SRP: registrar controllers criados por `track` e reprovar o teste que
/// deixar algum vivo. NAO faz: rastrear objetos do framework (isso e' papel
/// do `LeakTesting`, ligado em `test/flutter_test_config.dart`).
///
/// Por que existe: `IKortexController` **nao** e' um `ChangeNotifier`, entao o
/// leak tracker do Flutter nao o enxerga. Sem este gate, um controller
/// esquecido passa como "tudo verde".
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kortex/kortex.dart';

final List<IKortexController> _registry = [];

/// Registra [controller] para a checagem de descarte no fim do teste.
T track<T extends IKortexController>(T controller) {
  _registry.add(controller);
  return controller;
}

/// Limpa o registro (inicio de cada teste).
void resetTrackedControllers() => _registry.clear();

/// Devolve, de [controllers], os que ainda nao foram descartados.
List<IKortexController> leakedControllers(
  Iterable<IKortexController> controllers,
) => [
  for (final controller in controllers)
    if (!controller.isDisposed) controller,
];

/// Reprova quando algum controller de [controllers] nao foi descartado.
void assertAllDisposed(Iterable<IKortexController> controllers) {
  final alive = leakedControllers(controllers);
  expect(
    alive,
    isEmpty,
    reason:
        'Controllers nao descartados: '
        '${alive.map((controller) => controller.runtimeType).toList()}',
  );
}

/// Reprova o teste quando algum controller registrado ficou vivo.
void expectAllTrackedDisposed() {
  final alive = leakedControllers(_registry);
  _registry.clear();
  assertAllDisposed(alive);
}

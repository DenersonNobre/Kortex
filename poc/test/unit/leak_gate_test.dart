import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_testing/leak_tracker_testing.dart';
import 'package:poc/modules/clients/data/.index.dart';
import 'package:poc/modules/clients/features/.index.dart';
import 'package:poc/modules/clients/ui/clients_controller.dart';

import '../support/controller_lifecycle.dart';

/// Controller de clientes sobre store vazio e sem latencia.
ClientsController _controller() => ClientsController(
  DefaultClientUseCases(clients: InMemoryClientStore(latency: Duration.zero)),
);

/// Prova negativa dos DOIS gates da POC.
///
/// Um gate que nunca falhou nunca foi exercitado. Este arquivo cobre:
/// 1. `LeakTesting` esta' realmente ligado (e nao apenas importado);
/// 2. `assertAllDisposed` reprova controller vivo e aprova o descartado.
void main() {
  test('LeakTesting esta ligado pela config da suite', () {
    expect(LeakTesting.enabled, isTrue);
  });

  test(
    'gate de ciclo de vida reprova controller vivo e aprova o descartado',
    () {
      final leaked = _controller();
      final disposed = _controller()..dispose();

      // Presenca: controller vivo e' detectado e reprova.
      expect(leakedControllers([leaked]), hasLength(1));
      expect(() => assertAllDisposed([leaked]), throwsA(isA<TestFailure>()));

      // Ausencia com par de presenca: o descartado passa, sozinho e junto.
      expect(leakedControllers([disposed]), isEmpty);
      assertAllDisposed([disposed]);
      expect(
        () => assertAllDisposed([leaked, disposed]),
        throwsA(isA<TestFailure>()),
      );

      leaked.dispose();
    },
  );
}

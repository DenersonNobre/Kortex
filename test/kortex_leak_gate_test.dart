import 'package:flutter_test/flutter_test.dart';
import 'package:kortex/src/reactive/reactive.dart';
import 'package:leak_tracker/leak_tracker.dart';
import 'package:leak_tracker_testing/leak_tracker_testing.dart';

import 'support/controller_lifecycle.dart';

/// Objeto que o tracker conhece: despacha criacao e descarte.
class _Tracked {
  _Tracked() {
    LeakTracking.dispatchObjectCreated(
      library: 'package:kortex/test/kortex_leak_gate_test.dart',
      className: '_Tracked',
      object: this,
    );
  }

  void dispose() {
    LeakTracking.dispatchObjectDisposed(object: this);
  }
}

/// Controller concreto para provar o gate de ciclo de vida.
class _PlainController extends IKortexController {}

/// Prova negativa dos DOIS gates da suite.
///
/// O gate so vale se ele DETECTA vazamento. Este arquivo cobre:
/// 1. `LeakTesting` esta' realmente ligado (e nao apenas importado);
/// 2. `assertAllDisposed` reprova controller vivo e aprova o descartado —
///    camada necessaria porque `IKortexController` nao e' `ChangeNotifier`.
void main() {
  tearDown(LeakTracking.stop);

  test('LeakTesting esta ligado pela config da suite', () {
    expect(LeakTesting.enabled, isTrue);
  });

  test(
    'gate de ciclo de vida reprova controller vivo e aprova o descartado',
    () {
      final leaked = _PlainController();
      final disposed = _PlainController()..dispose();

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

  test('gate de leak tracking detecta objeto nao descartado', () async {
    LeakTracking.start(
      resetIfAlreadyStarted: true,
      config: LeakTrackingConfig.passive(),
    );
    LeakTracking.phase = const PhaseSettings.experimentalNotGCedOn();

    _Tracked();

    await forceGC(fullGcCycles: defaultNumberOfGcCycles);
    final leaks = await LeakTracking.collectLeaks();
    LeakTracking.stop();

    expect(leaks.notDisposed, isNotEmpty);
    expect(() => expect(leaks, isLeakFree), throwsA(isA<TestFailure>()));
  });
}

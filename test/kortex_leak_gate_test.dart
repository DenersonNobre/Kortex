import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/leak_tracker.dart';
import 'package:leak_tracker_testing/leak_tracker_testing.dart';

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

/// Prova negativa do gate de leak tracking.
///
/// O gate so vale se ele DETECTA vazamento. Este teste cria um objeto
/// rastreado e deliberadamente NAO descartado, e afirma que o tracker o
/// encontra e que o matcher `isLeakFree` reprovaria.
///
/// O tracking e' parado ao fim para que a coleta por arquivo (que roda no
/// tearDown do arquivo) nao reporte o vazamento proposital desta prova.
void main() {
  tearDown(LeakTracking.stop);

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

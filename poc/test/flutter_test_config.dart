/// Gate de vazamento de memoria da suite da POC.
///
/// Duas camadas, porque uma so' nao cobre o risco real:
/// 1. `LeakTesting` — objetos rastreados pelo framework (ChangeNotifier etc.);
/// 2. `track`/`assertAllDisposed` — `IKortexController`, que o framework nao
///    enxerga (nao e' `ChangeNotifier`).
///
/// Contrato do `flutter_tools`: o arquivo deve expor
/// `Future<void> testExecutable(FutureOr<void> Function())`.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_testing/leak_tracker_testing.dart';

import 'support/controller_lifecycle.dart';

/// Executa [testMain] com os dois gates ligados.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  LeakTesting.enable();
  setUp(resetTrackedControllers);
  tearDown(expectAllTrackedDisposed);
  await testMain();
}

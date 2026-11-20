/// Ativa o rastreamento de vazamentos de memoria na suite de testes.
///
/// O `flutter_test` so reporta vazamentos quando o leak tracking e' ligado
/// explicitamente (`LeakTracking.phase = PhaseSettings.ignored()` por padrao).
/// Com ele ligado, o reporter padrao reprova o teste que deixou objeto vivo.
///
/// Contrato do `flutter_tools`: o arquivo deve expor
/// `Future<void> testExecutable(FutureOr<void> Function())`, que o runner
/// chama com o `main` do arquivo de teste.
library;

import 'dart:async';

import 'package:leak_tracker_testing/leak_tracker_testing.dart';

/// Executa [testMain] com o leak tracking habilitado.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  LeakTesting.enable();
  await testMain();
}

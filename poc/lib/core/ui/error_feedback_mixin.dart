import 'package:flutter/foundation.dart';
import 'package:kortex/kortex.dart';

/// Mixin para padronizar canal reativo de erro em `IKortexController`.
mixin KortexErrorMixin on IKortexController {
  /// Mensagem de erro da última ação (`''` = sem erro).
  final KortexSignal<String> error = KortexSignal('');

  /// Publica [message] forçando reemissão mesmo se a mensagem repetir.
  void publishError(String message) {
    error.value = '';
    error.value = message;
  }

  @override
  @mustCallSuper
  void onDispose() {
    error.dispose();
    super.onDispose();
  }
}

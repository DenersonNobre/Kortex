import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

/// Exibe um [SnackBar] sempre que [error] emitir uma mensagem não vazia.
class KortexErrorSnackBarListener extends StatelessWidget {
  /// Cria um listener de erro acoplado a [error].
  const KortexErrorSnackBarListener({
    super.key,
    required this.error,
    required this.child,
  });

  /// Sinal de erro observado.
  final IKortex<String> error;

  /// Subárvore protegida pelo listener.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return KortexListener<String>(
      watch: () => error.value,
      listener: (listenerContext, message) {
        if (message.isEmpty) return;
        ScaffoldMessenger.of(listenerContext)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      },
      child: child,
    );
  }
}

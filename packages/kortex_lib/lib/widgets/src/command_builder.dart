import 'package:flutter/material.dart';
import 'package:kortex_lib/core/core.dart';

import 'observable_adapter.dart';
import 'reactive.dart' show NotifierBuilder;
import 'state_views.dart';

/// Widget construtor reativo para [Command].
///
/// Observa [Command.isExecuting] e [Command.result] via [asListenable],
/// renderizando os estados visuais correspondentes:
/// - Em execução ou sem resultado inicial: [loadingBuilder] (ou [Loading] padrão).
/// - Sucesso: [builder].
/// - Falha: [errorBuilder] (ou [ErrorRetryView] padrão).
class CommandBuilder<TSuccess, TFailure, TParam> extends StatelessWidget {
  const CommandBuilder({
    super.key,
    required this.command,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.retryParam,
    this.retryTooltip = 'Tentar novamente',
  });

  final Command<TSuccess, TFailure, TParam> command;
  final Widget Function(BuildContext context, TSuccess data) builder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, TFailure failure)? errorBuilder;
  final TParam? retryParam;
  final String retryTooltip;

  @override
  Widget build(BuildContext context) {
    return NotifierBuilder<bool>(
      listenable: command.isExecuting.asListenable(),
      builder: (context, executing) {
        return NotifierBuilder<IResult<TSuccess, TFailure>?>(
          listenable: command.result.asListenable(),
          builder: (context, result) {
            if (executing || result == null) {
              return loadingBuilder?.call(context) ?? const Loading();
            }
            if (result case Success(value: final data)) {
              return builder(context, data);
            }
            if (result case Failure(value: final failure)) {
              if (errorBuilder != null) {
                return errorBuilder!(context, failure);
              }
              final message = failure is IFailure
                  ? failure.message
                  : '$failure';
              return ErrorRetryView(
                message: message,
                onRetry: () => command.run(retryParam),
                retryTooltip: retryTooltip,
              );
            }
            return loadingBuilder?.call(context) ?? const Loading();
          },
        );
      },
    );
  }
}

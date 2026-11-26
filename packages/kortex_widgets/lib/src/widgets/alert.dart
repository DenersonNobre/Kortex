// Alert — utilitário de notificações efêmeras via SnackBar.
//
// Exibe mensagens flutuantes estilizadas e acessíveis, aderentes ao Material 3
// e ao ColorScheme do tema atual.

import 'package:flutter/material.dart';

abstract final class Alert {
  static void _show({
    required BuildContext context,
    required String title,
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required Color foregroundColor,
    Duration duration = const Duration(seconds: 4),
  }) {
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        content: Row(
          children: [
            Icon(icon, color: foregroundColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$title\n$message',
                style: TextStyle(
                  color: foregroundColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Alerta de erro com cores semânticas de erro do tema.
  static void error(
    BuildContext context, {
    String title = 'Erro',
    String message = 'Ocorreu um erro inesperado',
    Duration duration = const Duration(seconds: 4),
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    _show(
      context: context,
      title: title,
      message: message,
      icon: Icons.error_outline,
      backgroundColor: colorScheme.error,
      foregroundColor: colorScheme.onError,
      duration: duration,
    );
  }

  /// Alerta de sucesso com cores primárias / semânticas de sucesso do tema.
  static void success(
    BuildContext context, {
    String title = 'Sucesso',
    String message = 'Operação realizada com sucesso',
    Duration duration = const Duration(seconds: 4),
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    _show(
      context: context,
      title: title,
      message: message,
      icon: Icons.check_circle_outline,
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      duration: duration,
    );
  }

  /// Alerta informativo com cores de container primário.
  static void info(
    BuildContext context, {
    String title = 'Informação',
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    _show(
      context: context,
      title: title,
      message: message,
      icon: Icons.info_outline,
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
      duration: duration,
    );
  }

  /// Alerta de aviso/atenção.
  static void warning(
    BuildContext context, {
    String title = 'Atenção',
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    _show(
      context: context,
      title: title,
      message: message,
      icon: Icons.warning_amber_rounded,
      backgroundColor: colorScheme.tertiaryContainer,
      foregroundColor: colorScheme.onTertiaryContainer,
      duration: duration,
    );
  }

  /// Atalho de conveniência para inclusão / criação de registro.
  static void created(
    BuildContext context, {
    String title = 'Inclusão',
    String message = 'Registro criado com sucesso',
    Duration duration = const Duration(seconds: 4),
  }) {
    success(context, title: title, message: message, duration: duration);
  }

  /// Atalho de conveniência para atualização / alteração de registro.
  static void updated(
    BuildContext context, {
    String title = 'Atualização',
    String message = 'Registro atualizado com sucesso',
    Duration duration = const Duration(seconds: 4),
  }) {
    success(context, title: title, message: message, duration: duration);
  }

  /// Atalho de conveniência para exclusão / remoção de registro.
  static void deleted(
    BuildContext context, {
    String title = 'Exclusão',
    String message = 'Registro excluído com sucesso',
    Duration duration = const Duration(seconds: 4),
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    _show(
      context: context,
      title: title,
      message: message,
      icon: Icons.delete_outline,
      backgroundColor: colorScheme.error,
      foregroundColor: colorScheme.onError,
      duration: duration,
    );
  }
}

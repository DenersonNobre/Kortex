import 'package:flutter/material.dart';

class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    this.confirmColor,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final Color? confirmColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(child: Text(message)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: confirmColor ?? theme.colorScheme.primary,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}

/// Cabeçalho padrão para modais e bottom sheets, com ícone e botão de fechar.
class ModalHeader extends StatelessWidget {
  const ModalHeader({
    super.key,
    required this.title,
    this.icon,
    this.closeTooltip,
    this.onClose,
  });

  final String title;
  final Widget? icon;
  final String? closeTooltip;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        if (icon != null) ...[icon!, const SizedBox(width: 8)],
        Expanded(
          child: Text(title, style: theme.textTheme.titleMedium),
        ),
        IconButton(
          tooltip: closeTooltip,
          onPressed: onClose ?? () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }
}

/// Corpo padrão rolável para modais e bottom sheets, composto por [ModalHeader],
/// divisor e conteúdo opcional.
class ModalSheet extends StatelessWidget {
  const ModalSheet({
    super.key,
    required this.title,
    this.icon,
    this.child,
    this.closeTooltip,
    this.onClose,
    this.padding = const EdgeInsets.all(16),
  });

  final String title;
  final Widget? icon;
  final Widget? child;
  final String? closeTooltip;
  final VoidCallback? onClose;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final minHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 0.0;
        return SingleChildScrollView(
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ModalHeader(
                  title: title,
                  icon: icon,
                  closeTooltip: closeTooltip,
                  onClose: onClose,
                ),
                const Divider(),
                ?child,
              ],
            ),
          ),
        );
      },
    );
  }
}

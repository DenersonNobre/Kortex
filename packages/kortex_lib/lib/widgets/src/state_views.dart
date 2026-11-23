import 'package:flutter/material.dart';

/// Scaffold interno para estados centralizados com rolagem segura em altura
/// limitada ou ilimitada (mesma função estrutural de `EmptyState` e
/// `ErrorRetryView`).
class _CenteredScrollableColumn extends StatelessWidget {
  const _CenteredScrollableColumn({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final minHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 0.0;
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: children,
              ),
            ),
          ),
        );
      },
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.icon = Icons.inbox_outlined,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _CenteredScrollableColumn(
      children: [
        Icon(icon, size: 56, color: theme.colorScheme.outline),
        const SizedBox(height: 12),
        Text(title, style: theme.textTheme.titleMedium),
        if (message != null) ...[
          const SizedBox(height: 6),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (action != null) ...[const SizedBox(height: 12), action!],
      ],
    );
  }
}

class ErrorRetryView extends StatelessWidget {
  const ErrorRetryView({
    super.key,
    this.message,
    this.onRetry,
    this.retryTooltip,
    this.icon = Icons.error_outline,
  });

  final String? message;
  final VoidCallback? onRetry;
  final String? retryTooltip;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _CenteredScrollableColumn(
      children: [
        Icon(icon, size: 48, color: theme.colorScheme.error),
        if (message != null) ...[
          const SizedBox(height: 12),
          Text(message!, textAlign: TextAlign.center),
        ],
        if (onRetry != null) ...[
          const SizedBox(height: 12),
          IconButton(
            tooltip: retryTooltip,
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ],
    );
  }
}

class Loading extends StatelessWidget {
  const Loading({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (label != null) ...[const SizedBox(height: 8), Text(label!)],
        ],
      ),
    );
  }
}

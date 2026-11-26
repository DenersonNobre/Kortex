import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

class AsyncButton extends StatelessWidget {
  const AsyncButton({
    super.key,
    required this.loading,
    required this.onPressed,
    required this.child,
    this.enabled = true,
    this.loadingChild,
    this.style,
  });

  final ValueListenable<bool> loading;
  final VoidCallback? onPressed;
  final bool enabled;
  final Widget child;
  final Widget? loadingChild;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    return NotifierBuilder<bool>(
      listenable: loading,
      builder: (context, isLoading) {
        final content = isLoading
            ? loadingChild ??
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      child,
                    ],
                  )
            : child;
        return ElevatedButton(
          style: style,
          onPressed: isLoading || !enabled || onPressed == null
              ? null
              : onPressed,
          child: content,
        );
      },
    );
  }
}

/// Builder canônico para observar um [ValueListenable] sem parâmetro `child`,
/// com semântica direta `(context, value)`.
class NotifierBuilder<T> extends StatelessWidget {
  const NotifierBuilder({
    super.key,
    required this.listenable,
    required this.builder,
  });

  final ValueListenable<T> listenable;
  final Widget Function(BuildContext context, T value) builder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<T>(
      valueListenable: listenable,
      builder: (context, value, _) => builder(context, value),
    );
  }
}

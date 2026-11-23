import 'package:flutter/material.dart';

class Caption extends StatelessWidget {
  const Caption({super.key, this.prefix, this.suffix, required this.text});

  final Widget? prefix;
  final Widget? suffix;
  final Widget text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (prefix != null) ...[prefix!, const SizedBox(width: 8)],
        Expanded(child: text),
        if (suffix != null) ...[const SizedBox(width: 8), suffix!],
      ],
    );
  }
}

class Label extends StatelessWidget {
  const Label({super.key, required this.text, this.color, this.height = 25});

  final String text;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return SizedBox(
      height: height,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(color: color),
        ),
      ),
    );
  }
}

class ShadedText extends StatelessWidget {
  const ShadedText({
    super.key,
    this.text = '',
    this.fontSize,
    this.color,
    this.shadow,
  });

  final String text;
  final double? fontSize;
  final Color? color;
  final Shadow? shadow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: color,
        fontSize: fontSize,
        shadows: shadow == null ? null : [shadow!],
      ),
    );
  }
}

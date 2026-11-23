import 'package:flutter/material.dart';

/// Cabeçalho tipográfico leve para seções, com subtítulo e ação opcionais.
class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.fontSize,
    this.textStyle,
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final double? fontSize;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle =
        textStyle ??
        theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600);
    final titleStyle = fontSize == null
        ? baseStyle
        : baseStyle?.copyWith(fontSize: fontSize);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: titleStyle),
              if (subtitle != null)
                Text(subtitle!, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        if (action != null) ...[const SizedBox(width: 8), action!],
      ],
    );
  }
}

/// Barra/faixa estrutural de topo com altura, fundo, alinhamento e ações.
class TitlePanel extends StatelessWidget {
  const TitlePanel({
    super.key,
    required Widget title,
    this.height = 50,
    this.backgroundColor,
    this.padding = EdgeInsets.zero,
    this.margin = EdgeInsets.zero,
    this.alignment = Alignment.centerLeft,
    this.actions = const [],
  }) : _titleWidget = title,
       _titleText = null,
       _titleColor = null;

  /// Atalho `const` para exibir um título textual com estilo de cabeçalho.
  const TitlePanel.text({
    super.key,
    required String title,
    this._titleColor,
    this.height = 50,
    this.backgroundColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
    this.margin = EdgeInsets.zero,
    this.alignment = Alignment.centerLeft,
    this.actions = const [],
  }) : _titleWidget = null,
       _titleText = title;

  final Widget? _titleWidget;
  final String? _titleText;
  final Color? _titleColor;
  final double height;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final AlignmentGeometry alignment;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final resolvedTitle =
        _titleWidget ??
        Text(
          _titleText ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: _titleColor),
        );

    return Container(
      margin: margin,
      height: height,
      color: backgroundColor,
      padding: padding,
      alignment: alignment,
      child: Row(
        children: [
          Expanded(child: resolvedTitle),
          ...actions,
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Exibe um par rótulo/valor em linha ([Axis.horizontal]) ou coluna ([Axis.vertical]).
///
/// Substitui `DetailLine`, `DetailColumn` e `KeyValueText` com suporte a
/// estilos combinados, largura fixa de rótulo ([labelSpace]), fundo e separador.
class DetailItem extends StatelessWidget {
  const DetailItem({
    super.key,
    this.label,
    this.value,
    this.direction = Axis.horizontal,
    this.separator = '',
    this.style,
    this.labelStyle,
    this.valueStyle,
    this.labelSpace,
    this.spacing = 6,
    this.backgroundColor,
    this.padding,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment,
  }) : _mutedLabelDefault = false;

  /// Atalho `const` estilo chave-valor com separador `':'` por padrão.
  const DetailItem.keyValue({
    super.key,
    required String this.label,
    required String this.value,
    this.direction = Axis.horizontal,
    this.separator = ':',
    this.style,
    this.labelStyle,
    this.valueStyle,
    this.labelSpace,
    this.spacing = 6,
    this.backgroundColor,
    this.padding,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  }) : _mutedLabelDefault = true;

  final String? label;
  final String? value;
  final Axis direction;
  final String separator;
  final TextStyle? style;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;
  final double? labelSpace;
  final double spacing;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment? crossAxisAlignment;
  final bool _mutedLabelDefault;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = style ?? theme.textTheme.bodyMedium;
    final defaultLabelStyle = _mutedLabelDefault && style == null
        ? baseStyle?.copyWith(color: theme.colorScheme.onSurfaceVariant)
        : baseStyle;
    final resolvedLabelStyle = labelStyle != null
        ? baseStyle?.merge(labelStyle) ?? labelStyle
        : defaultLabelStyle;
    final resolvedValueStyle = valueStyle != null
        ? baseStyle?.merge(valueStyle) ?? valueStyle
        : baseStyle;

    final labelText = label == null ? null : '$label$separator';

    final Widget content = direction == Axis.vertical
        ? Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment ?? CrossAxisAlignment.start,
            children: [
              if (labelText != null) Text(labelText, style: resolvedLabelStyle),
              if (value != null) Text(value!, style: resolvedValueStyle),
            ],
          )
        : Row(
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment ?? CrossAxisAlignment.center,
            children: [
              if (labelText != null)
                Flexible(
                  child: SizedBox(
                    width: labelSpace,
                    child: Text(
                      labelText,
                      maxLines: labelSpace != null ? 1 : null,
                      overflow: labelSpace != null
                          ? TextOverflow.ellipsis
                          : null,
                      style: resolvedLabelStyle,
                    ),
                  ),
                ),
              if (labelText != null && labelSpace == null && spacing > 0)
                SizedBox(width: spacing),
              Expanded(
                child: value == null
                    ? const SizedBox.shrink()
                    : Text(value!, style: resolvedValueStyle),
              ),
            ],
          );

    final resolvedPadding =
        padding ??
        (direction == Axis.vertical
            ? const EdgeInsets.all(4)
            : const EdgeInsets.symmetric(horizontal: 4));

    return Container(
      padding: resolvedPadding,
      decoration: backgroundColor == null
          ? null
          : BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(4),
            ),
      child: content,
    );
  }
}

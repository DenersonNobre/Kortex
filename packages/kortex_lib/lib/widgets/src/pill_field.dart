import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Campo de texto com borda arredondada e cores derivadas do tema atual.
class PillField extends StatelessWidget {
  const PillField({
    super.key,
    this.controller,
    required this.label,
    this.icon,
    this.error,
    this.obscure = false,
    this.enabled = true,
    this.readOnly = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.inputFormatters,
    this.maxLength,
    this.suffix,
    this.onSubmitted,
    this.onTap,
    this.borderRadius = defaultBorderRadius,
  });

  static const double defaultBorderRadius = 28;

  final TextEditingController? controller;
  final String label;
  final IconData? icon;
  final String? error;
  final bool obscure;
  final bool enabled;
  final bool readOnly;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final Widget? suffix;
  final VoidCallback? onSubmitted;
  final VoidCallback? onTap;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return TextField(
      controller: controller,
      enabled: enabled,
      readOnly: readOnly,
      obscureText: obscure,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      onTap: onTap,
      onSubmitted: (_) => onSubmitted?.call(),
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: theme.textTheme.bodyMedium?.copyWith(
          color: colors.onSurfaceVariant,
        ),
        prefixIcon: icon == null
            ? null
            : Icon(icon, color: colors.onSurfaceVariant),
        suffixIcon: suffix,
        errorText: error,
        counterText: maxLength == null ? null : '',
        filled: true,
        fillColor: colors.surfaceContainer,
        border: _border(colors.outlineVariant),
        enabledBorder: _border(colors.outlineVariant),
        focusedBorder: _border(colors.primary, 2),
        errorBorder: _border(colors.error),
        focusedErrorBorder: _border(colors.error, 2),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(color: color, width: width),
      );
}

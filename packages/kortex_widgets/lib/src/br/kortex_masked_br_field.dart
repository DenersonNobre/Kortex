import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kortex/kortex.dart';
import 'package:kortex_forms/kortex_forms.dart';

/// Base masked text field bound to a [KortexField<String>].
class KortexMaskedBrField extends StatelessWidget {
  /// Creates a masked input bound to [field].
  const KortexMaskedBrField({
    super.key,
    required this.field,
    required this.label,
    required this.format,
    this.keyboardType = TextInputType.number,
  });

  /// Reactive form field.
  final KortexField<String> field;

  /// Input label.
  final String label;

  /// Formatter applied on every keystroke.
  final String Function(String raw) format;

  /// Keyboard type.
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    return KortexWatch(
      builder: (context, _) => TextFormField(
        initialValue: field.value,
        keyboardType: keyboardType,
        inputFormatters: [
          TextInputFormatter.withFunction((_, newValue) {
            final formatted = format(newValue.text);
            return TextEditingValue(
              text: formatted,
              selection: TextSelection.collapsed(offset: formatted.length),
            );
          }),
        ],
        decoration: InputDecoration(
          labelText: label,
          errorText: field.touched.value ? field.error.value : null,
        ),
        onChanged: (value) => field.value = value,
      ),
    );
  }
}

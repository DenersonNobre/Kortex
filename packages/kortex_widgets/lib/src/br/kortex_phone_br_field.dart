import 'package:flutter/material.dart';
import 'package:kortex_br/kortex_br.dart';
import 'package:kortex_forms/kortex_forms.dart';

import 'kortex_masked_br_field.dart';

/// Brazilian phone input field (`(00) 0000-0000` / `(00) 00000-0000`).
class KortexPhoneBrField extends StatelessWidget {
  /// Creates a Brazilian phone input bound to [field].
  const KortexPhoneBrField({
    super.key,
    required this.field,
    this.label = 'Telefone',
  });

  /// Reactive form field.
  final KortexField<String> field;

  /// Input label.
  final String label;

  @override
  Widget build(BuildContext context) => KortexMaskedBrField(
    field: field,
    label: label,
    format: PhoneBrFormatter.format,
    keyboardType: TextInputType.phone,
  );
}

import 'package:flutter/material.dart';
import 'package:kortex_br/kortex_br.dart';
import 'package:kortex_forms/kortex_forms.dart';

import 'kortex_masked_br_field.dart';

/// Brazilian CPF input field (`000.000.000-00`).
class KortexCpfField extends StatelessWidget {
  /// Creates a CPF input bound to [field].
  const KortexCpfField({super.key, required this.field, this.label = 'CPF'});

  /// Reactive form field.
  final KortexField<String> field;

  /// Input label.
  final String label;

  @override
  Widget build(BuildContext context) => KortexMaskedBrField(
    field: field,
    label: label,
    format: CpfFormatter.format,
  );
}

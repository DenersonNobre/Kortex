import 'package:flutter/material.dart';
import 'package:kortex_br/kortex_br.dart';
import 'package:kortex_forms/kortex_forms.dart';

import 'kortex_masked_br_field.dart';

/// Brazilian CEP input field (`00000-000`).
class KortexCepField extends StatelessWidget {
  /// Creates a CEP input bound to [field].
  const KortexCepField({super.key, required this.field, this.label = 'CEP'});

  /// Reactive form field.
  final KortexField<String> field;

  /// Input label.
  final String label;

  @override
  Widget build(BuildContext context) => KortexMaskedBrField(
    field: field,
    label: label,
    format: CepFormatter.format,
  );
}

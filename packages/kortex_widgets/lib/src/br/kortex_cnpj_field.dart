import 'package:flutter/material.dart';
import 'package:kortex_br/kortex_br.dart';
import 'package:kortex_forms/kortex_forms.dart';

import 'kortex_masked_br_field.dart';

/// Brazilian CNPJ input field (`00.000.000/0000-00`).
class KortexCnpjField extends StatelessWidget {
  /// Creates a CNPJ input bound to [field].
  const KortexCnpjField({super.key, required this.field, this.label = 'CNPJ'});

  /// Reactive form field.
  final KortexField<String> field;

  /// Input label.
  final String label;

  @override
  Widget build(BuildContext context) => KortexMaskedBrField(
    field: field,
    label: label,
    format: CnpjFormatter.format,
  );
}

import 'package:flutter/material.dart';
import 'package:kortex_br/kortex_br.dart';
import 'package:kortex_forms/kortex_forms.dart';

import 'kortex_masked_br_field.dart';

/// Brazilian Real (BRL) currency input field (`R$ 1.234,56`).
class KortexBrlCurrencyField extends StatelessWidget {
  /// Creates a BRL currency input bound to [field].
  const KortexBrlCurrencyField({
    super.key,
    required this.field,
    this.label = 'Valor (R\$)',
  });

  /// Reactive form field.
  final KortexField<String> field;

  /// Input label.
  final String label;

  @override
  Widget build(BuildContext context) => KortexMaskedBrField(
    field: field,
    label: label,
    format: (raw) {
      final cents = BrlCurrencyFormatter.parseToCents(raw);
      return cents == null ? '' : BrlCurrencyFormatter.formatCents(cents);
    },
  );
}

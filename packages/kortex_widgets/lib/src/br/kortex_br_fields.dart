import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kortex/kortex.dart';
import 'package:kortex_br/kortex_br.dart';
import 'package:kortex_forms/kortex_forms.dart';

/// Base masked text field bound to a [KortexField<String>].
class _KortexMaskedBrField extends StatelessWidget {
  const _KortexMaskedBrField({
    required this.field,
    required this.label,
    required this.format,
    this.keyboardType = TextInputType.number,
  });

  final KortexField<String> field;
  final String label;
  final String Function(String raw) format;
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

/// Brazilian CPF input field (`000.000.000-00`).
class KortexCpfField extends StatelessWidget {
  /// Creates a CPF input bound to [field].
  const KortexCpfField({super.key, required this.field, this.label = 'CPF'});

  /// Reactive form field.
  final KortexField<String> field;

  /// Input label.
  final String label;

  @override
  Widget build(BuildContext context) => _KortexMaskedBrField(
    field: field,
    label: label,
    format: CpfFormatter.format,
  );
}

/// Brazilian CNPJ input field (`00.000.000/0000-00`).
class KortexCnpjField extends StatelessWidget {
  /// Creates a CNPJ input bound to [field].
  const KortexCnpjField({super.key, required this.field, this.label = 'CNPJ'});

  /// Reactive form field.
  final KortexField<String> field;

  /// Input label.
  final String label;

  @override
  Widget build(BuildContext context) => _KortexMaskedBrField(
    field: field,
    label: label,
    format: CnpjFormatter.format,
  );
}

/// Brazilian CEP input field (`00000-000`).
class KortexCepField extends StatelessWidget {
  /// Creates a CEP input bound to [field].
  const KortexCepField({super.key, required this.field, this.label = 'CEP'});

  /// Reactive form field.
  final KortexField<String> field;

  /// Input label.
  final String label;

  @override
  Widget build(BuildContext context) => _KortexMaskedBrField(
    field: field,
    label: label,
    format: CepFormatter.format,
  );
}

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
  Widget build(BuildContext context) => _KortexMaskedBrField(
    field: field,
    label: label,
    format: PhoneBrFormatter.format,
    keyboardType: TextInputType.phone,
  );
}

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
  Widget build(BuildContext context) => _KortexMaskedBrField(
    field: field,
    label: label,
    format: (raw) {
      final cents = BrlCurrencyFormatter.parseToCents(raw);
      return cents == null ? '' : BrlCurrencyFormatter.formatCents(cents);
    },
  );
}

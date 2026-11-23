import 'package:flutter/services.dart';
import 'package:kortex_lib/brlib/src/input_formatters/digit_mask_input_formatter.dart';

/// Formata um CNPJ enquanto o usuário digita, aceitando o formato
/// alfanumérico (letras nas posições `A` da máscara) além do numérico.
class CnpjInputFormatter extends TextInputFormatter {
  CnpjInputFormatter()
    : _numeric = DigitMaskInputFormatter(
        mask: '##.###.###/####-##',
        maxCharacters: 14,
      );

  final DigitMaskInputFormatter _numeric;
  final DigitMaskInputFormatter _alphanumeric = DigitMaskInputFormatter(
    mask: 'AA.AAA.AAA/AAAA-##',
    maxCharacters: 14,
    allowLetters: true,
  );

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final upper = newValue.text.toUpperCase();
    final normalized = newValue.copyWith(text: upper);
    final hasLetter = RegExp('[A-Z]').hasMatch(upper);
    return (hasLetter ? _alphanumeric : _numeric).formatEditUpdate(
      oldValue,
      normalized,
    );
  }
}

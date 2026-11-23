import 'package:flutter/services.dart';
import 'package:kortex_lib/brlib/src/input_formatters/digit_mask_input_formatter.dart';

/// Formata telefone brasileiro enquanto o usuário digita: fixo
/// (`(##) ####-####`) ou celular (`(##) #####-####`), conforme a
/// quantidade de dígitos.
class PhoneBrInputFormatter extends TextInputFormatter {
  PhoneBrInputFormatter();

  final DigitMaskInputFormatter _landline = DigitMaskInputFormatter(
    mask: '(##) ####-####',
    maxCharacters: 10,
  );
  final DigitMaskInputFormatter _mobile = DigitMaskInputFormatter(
    mask: '(##) #####-####',
    maxCharacters: 11,
  );

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    return (digits.length > 10 ? _mobile : _landline).formatEditUpdate(
      oldValue,
      newValue,
    );
  }
}

import 'package:flutter/services.dart';

/// Formata números inteiros com separador de milhar pt-BR (`.`) enquanto o usuário digita.
///
/// Os dígitos são interpretados da direita para a esquerda como valor inteiro
/// (ex.: digitar 1,2,3,4 -> "1.234"). Usado para campos de quantidade/estoque.
class IntegerPtBrInputFormatter extends TextInputFormatter {
  IntegerPtBrInputFormatter({this.maxDigits});

  final int? maxDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    // Remove zeros à esquerda, preservando um único zero.
    digits = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (digits.isEmpty) {
      digits = '0';
    }
    final max = maxDigits;
    if (max != null && digits.length > max) {
      digits = digits.substring(0, max);
    }
    final formatted = _format(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _format(String digits) {
    final buffer = StringBuffer();
    final length = digits.length;
    for (var i = 0; i < length; i++) {
      final indexFromEnd = length - i;
      buffer.write(digits[i]);
      if (indexFromEnd > 1 && (indexFromEnd - 1) % 3 == 0) {
        buffer.write('.');
      }
    }
    return buffer.toString();
  }
}

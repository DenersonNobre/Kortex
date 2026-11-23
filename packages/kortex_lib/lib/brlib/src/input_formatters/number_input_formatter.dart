import 'package:flutter/services.dart';

/// Formata número como valor monetário pt-BR (centavos) enquanto o usuário
/// digita, sem depender de `intl`.
class NumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    final intValue = int.tryParse(digits);
    if (intValue == null ||
        (intValue == 0 && newValue.text.length < oldValue.text.length)) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    final formatted = formatPtBr(intValue, 2);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Formata centavos como número pt-BR com agrupamento de milhar e casas
/// decimais configuráveis (substitui `NumberFormat` do `intl`).
String formatPtBr(int cents, int decimalDigits) {
  final negative = cents < 0;
  final abs = cents.abs();
  var divisor = 1;
  for (var i = 0; i < decimalDigits; i++) {
    divisor *= 10;
  }
  final intPart = abs ~/ divisor;
  final fracPart = abs % divisor;
  final intStr = intPart.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < intStr.length; i++) {
    if (i > 0 && (intStr.length - i) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(intStr[i]);
  }
  if (decimalDigits == 0) {
    return '${negative ? '-' : ''}$buffer';
  }
  final fracStr = fracPart.toString().padLeft(decimalDigits, '0');
  return '${negative ? '-' : ''}$buffer,$fracStr';
}

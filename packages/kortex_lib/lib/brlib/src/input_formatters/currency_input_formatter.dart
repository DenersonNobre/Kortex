import 'package:flutter/services.dart';

import 'number_input_formatter.dart';

/// Formata moeda com símbolo e separadores configuráveis, sem depender de
/// `intl`.
class CurrencyInputFormatter extends TextInputFormatter {
  CurrencyInputFormatter({
    this.symbol = '',
    this.thousandsSeparator = ',',
    this.decimalSeparator = '.',
    this.decimalDigits = 2,
  });

  final String symbol;
  final String thousandsSeparator;
  final String decimalSeparator;
  final int decimalDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.selection.baseOffset == 0) {
      return newValue.copyWith(
        text: '',
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    final newText = _formatCurrency(newValue.text);
    var cursorPosition =
        newText.length - newValue.text.length + newValue.selection.baseOffset;
    cursorPosition = cursorPosition.clamp(0, newText.length);

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }

  String _formatCurrency(String inputText) {
    final cleaned = inputText
        .replaceAll(thousandsSeparator, '')
        .replaceAll(decimalSeparator, '');
    final digits = cleaned.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return '';
    }

    final cents = int.tryParse(digits) ?? 0;
    return '$symbol${formatPtBr(cents, decimalDigits)}';
  }
}

import 'package:flutter/services.dart';

/// Formata valores monetários com símbolo `R$` enquanto o usuário digita.
class MoneyInputFormatter extends TextInputFormatter {
  MoneyInputFormatter({required this.size, required this.decimal});

  final int size;
  final int decimal;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (text.length > size + decimal) {
      text = text.substring(0, size + decimal);
    }
    var formattedText = '';
    if (text.isNotEmpty) {
      formattedText = 'R\$ ';
      if (decimal > 0) {
        if (text.length <= size) {
          formattedText += text;
        } else {
          formattedText += '${text.substring(0, size)},${text.substring(size)}';
        }
      } else {
        formattedText += text;
      }
    }
    var selectionIndex = formattedText.length;
    if (decimal > 0 && text.length > size) {
      selectionIndex--;
    }
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}

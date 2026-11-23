import 'package:flutter/services.dart';

/// Formata data enquanto o usuário digita, seguindo o padrão informado
/// (ex.: `dd/MM/yyyy` ou `##/##/####`).
class DateInputFormatter extends TextInputFormatter {
  DateInputFormatter({required this.format});

  final String format;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var j = 0;
    var newText = '';
    for (var i = 0; i < newValue.text.length; i++) {
      if (j < format.length && format[j] == '/') {
        newText += '/';
        j++;
      }
      if (j < format.length &&
          (format[j] == 'd' || format[j] == 'M' || format[j] == 'y')) {
        newText += newValue.text[i];
        j++;
      }
    }
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

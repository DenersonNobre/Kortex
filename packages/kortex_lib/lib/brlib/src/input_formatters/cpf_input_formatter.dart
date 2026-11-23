import 'package:kortex_lib/brlib/src/input_formatters/digit_mask_input_formatter.dart';

/// Formata um CPF no padrão `###.###.###-##` enquanto o usuário digita.
class CpfInputFormatter extends DigitMaskInputFormatter {
  CpfInputFormatter() : super(mask: '###.###.###-##', maxCharacters: 11);
}

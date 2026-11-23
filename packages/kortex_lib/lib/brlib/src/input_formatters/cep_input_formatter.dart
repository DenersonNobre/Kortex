import 'package:kortex_lib/brlib/src/input_formatters/digit_mask_input_formatter.dart';

/// Formata um CEP no padrão `#####-###` enquanto o usuário digita.
class CepInputFormatter extends DigitMaskInputFormatter {
  CepInputFormatter() : super(mask: '#####-###', maxCharacters: 8);
}

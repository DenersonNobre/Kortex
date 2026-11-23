import 'package:flutter_test/flutter_test.dart';
import 'package:kortex_lib/kortex_lib.dart';

void main() {
  group('IntegerPtBrInputFormatter', () {
    late IntegerPtBrInputFormatter formatter;

    setUp(() {
      formatter = IntegerPtBrInputFormatter();
    });

    test('retorna vazio quando o texto estiver vazio', () {
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: ''),
      );
      expect(result.text, '');
      expect(result.selection.baseOffset, 0);
    });

    test('remove caracteres não numéricos e formata milhares', () {
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: 'abc1234xyz'),
      );
      expect(result.text, '1.234');
      expect(result.selection.baseOffset, 5);
    });

    test('formata números grandes com múltiplos separadores', () {
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '1234567'),
      );
      expect(result.text, '1.234.567');
    });

    test('remove zeros à esquerda mantendo apenas um zero quando isolado', () {
      final zeroResult = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '000'),
      );
      expect(zeroResult.text, '0');

      final numResult = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '00150'),
      );
      expect(numResult.text, '150');
    });

    test('respeita maxDigits quando informado', () {
      final limitedFormatter = IntegerPtBrInputFormatter(maxDigits: 4);
      final result = limitedFormatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '123456'),
      );
      expect(result.text, '1.234');
    });
  });
}

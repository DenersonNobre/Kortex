import 'package:kortex_core/core/core.dart';
import 'package:test/test.dart';

void main() {
  group('Money', () {
    test('usa unidade mínima inteira e mantém moeda e escala', () {
      final money = Money.fromMinorUnits(12345, currencyCode: 'USD', scale: 2);

      expect(money.minorUnits, BigInt.from(12345));
      expect(money.currencyCode, 'USD');
      expect(money.scale, 2);
      expect(money.format(decimalSeparator: '.'), '123.45');
    });

    test('faz parsing com separadores explícitos e arredonda por texto', () {
      final result = Money.tryParse(
        '1.234,505',
        currencyCode: 'BRL',
        scale: 2,
        decimalSeparator: ',',
        groupSeparator: '.',
      );

      expect(result.value?.minorUnits, BigInt.from(123451));
      expect(
        result.value?.format(decimalSeparator: ',', groupSeparator: '.'),
        '1.234,51',
      );
    });

    test('arredonda metade para longe de zero também em valor negativo', () {
      final result = Money.tryParse(
        '-1.005',
        currencyCode: 'USD',
        scale: 2,
        decimalSeparator: '.',
      );

      expect(result.value?.minorUnits, BigInt.from(-101));
    });

    test('permite aritmética somente entre moeda e escala iguais', () {
      final first = Money.fromMinorUnits(250, currencyCode: 'EUR', scale: 2);
      final second = Money.fromMinorUnits(75, currencyCode: 'EUR', scale: 2);
      final differentCurrency = Money.fromMinorUnits(
        100,
        currencyCode: 'USD',
        scale: 2,
      );

      expect(first.add(second).minorUnits, BigInt.from(325));
      expect(first.subtract(second).minorUnits, BigInt.from(175));
      expect(
        () => first.add(differentCurrency),
        throwsA(isA<MoneyCurrencyMismatch>()),
      );
    });

    test('retorna falha tipada para texto inválido', () {
      final result = Money.tryParse(
        '1,23',
        currencyCode: 'USD',
        scale: 2,
        decimalSeparator: '.',
      );

      expect(result.isFailure, isTrue);
      expect(result.failure, MoneyParseError.invalidFormat);
    });

    test('formata valores negativos e escala zero', () {
      final money = Money.fromMinorUnits(-1234, currencyCode: 'JPY', scale: 0);

      expect(
        money.format(decimalSeparator: '.', groupSeparator: ','),
        '-1,234',
      );
    });
  });
}

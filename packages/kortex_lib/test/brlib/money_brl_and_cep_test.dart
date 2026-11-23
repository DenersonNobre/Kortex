import 'package:kortex_lib/kortex_lib.dart';
import 'package:test/test.dart';

void main() {
  group('MoneyBrlX', () {
    test('fromCents cria Money em BRL com escala 2', () {
      final m = MoneyBrlX.fromCents(12345);
      expect(m.currencyCode, 'BRL');
      expect(m.scale, 2);
      expect(m.cents, 12345);
      expect(m.toDouble, 123.45);
      expect(m.formatted, '123,45');
      expect(m.formattedBrl, 'R\$ 123,45');
      expect(m.isZero, isFalse);
    });

    test('fromReal converte double arredondando centavos', () {
      final m = MoneyBrlX.fromReal(99.999);
      expect(m.cents, 10000);
      expect(m.formatted, '100,00');

      final zero = MoneyBrlX.zero();
      expect(zero.cents, 0);
      expect(zero.isZero, isTrue);
    });

    test('tryParseBrl e tryParseBrlOrNull convertem texto formatado pt-BR', () {
      final m1 = MoneyBrlX.tryParseBrlOrNull('1.250,75');
      expect(m1, isNotNull);
      expect(m1!.cents, 125075);
      expect(m1.formattedBrl, 'R\$ 1.250,75');

      final mInvalido = MoneyBrlX.tryParseBrlOrNull('abc');
      expect(mInvalido, isNull);

      final r = MoneyBrlX.tryParseBrl('');
      expect(r.isFailure, isTrue);
    });
  });

  group('CepValidator aprimorado', () {
    test('isValid aceita 8 dígitos válidos e rejeita dígitos repetidos', () {
      expect(CepValidator.isValid('01001-000'), isTrue);
      expect(CepValidator.isValid('01001000'), isTrue);
      expect(CepValidator.isValid('11111-111'), isFalse);
      expect(CepValidator.isValid('00000000'), isFalse);
      expect(CepValidator.isValid('123'), isFalse);
    });

    test('validate devolve mensagem de erro ou null', () {
      expect(CepValidator.validate(''), isNull);
      expect(CepValidator.validate('', obrigatorio: true), 'CEP obrigatório');
      expect(CepValidator.validate('11111111'), 'CEP inválido');
      expect(CepValidator.validate('01001000'), isNull);
    });
  });
}

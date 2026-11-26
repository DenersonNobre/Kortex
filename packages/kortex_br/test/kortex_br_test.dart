import 'package:kortex_br/kortex_br.dart';
import 'package:test/test.dart';

void main() {
  group('digitsOnly / unmask', () {
    test('strips non-digit characters', () {
      expect(digitsOnly('123.456.789-00'), '12345678900');
      expect(unmask('(11) 98888-7777'), '11988887777');
    });
  });

  group('CPF', () {
    test('validates valid CPFs including leading zeros', () {
      expect(CpfValidator.isValid('52998224725'), isTrue);
      expect(CpfValidator.isValid('529.982.247-25'), isTrue);
      expect(CpfValidator.isValid('01234567890'), isTrue);
      expect(CpfValidator.isValid('01234567891'), isFalse);
    });

    test('rejects repeated digits, null, empty, and corrupted check digit', () {
      expect(CpfValidator.isValid(null), isFalse);
      expect(CpfValidator.isValid(''), isFalse);
      expect(CpfValidator.isValid('111.111.111-11'), isFalse);
      expect(CpfValidator.isValid('52998224726'), isFalse);
    });

    test('formats CPF progressively', () {
      expect(CpfFormatter.format('52998224725'), '529.982.247-25');
      expect(CpfFormatter.format('52998'), '529.98');
    });
  });

  group('CNPJ', () {
    test('validates valid and invalid CNPJs', () {
      expect(CnpjValidator.isValid('11222333000181'), isTrue);
      expect(CnpjValidator.isValid('11.222.333/0001-81'), isTrue);
      expect(CnpjValidator.isValid('11222333000182'), isFalse);
      expect(CnpjValidator.isValid('00000000000000'), isFalse);
      expect(CnpjValidator.isValid(null), isFalse);
    });

    test('formats CNPJ', () {
      expect(CnpjFormatter.format('11222333000181'), '11.222.333/0001-81');
    });
  });

  group('CEP & PhoneBR', () {
    test('validates and formats CEP', () {
      expect(CepValidator.isValid('01001-000'), isTrue);
      expect(CepValidator.isValid('0100100'), isFalse);
      expect(CepFormatter.format('01001000'), '01001-000');
    });

    test('validates and formats PhoneBR', () {
      expect(PhoneBrValidator.isValid('(11) 98888-7777'), isTrue);
      expect(PhoneBrValidator.isValid('(11) 3333-4444'), isTrue);
      expect(PhoneBrValidator.isValid('(11) 88888-7777'), isFalse);
      expect(PhoneBrFormatter.format('11988887777'), '(11) 98888-7777');
    });
  });

  group('BRL, PIX & MercosulPlate', () {
    test('formats and parses BRL cents', () {
      expect(BrlCurrencyFormatter.formatCents(123456), r'R$ 1.234,56');
      expect(BrlCurrencyFormatter.formatCents(-50), r'-R$ 0,50');
      expect(BrlCurrencyFormatter.parseToCents(r'R$ 1.234,56'), 123456);
      expect(BrlCurrencyFormatter.parseToCents(null), isNull);
    });

    test('validates PIX keys and Mercosul plates', () {
      expect(PixKeyValidator.isValid('dev@bonusoft.com.br'), isTrue);
      expect(PixKeyValidator.isValid('+5511988887777'), isTrue);
      expect(PixKeyValidator.isValid('52998224725'), isTrue);
      expect(PixKeyValidator.isValid('invalid'), isFalse);

      expect(MercosulPlateValidator.isValid('ABC1D23'), isTrue);
      expect(MercosulPlateValidator.isValid('ABC1234'), isFalse);
    });
  });
}

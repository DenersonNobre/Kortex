import 'package:kortex_lib/brlib/brlib.dart';
import 'package:test/test.dart';

void main() {
  group('validadores brasileiros', () {
    test('CPF aceita dígitos verificadores válidos e rejeita repetição', () {
      expect(CpfValidator.isValid('529.982.247-25'), isTrue);
      expect(CpfValidator.isValid('111.111.111-11'), isFalse);
      expect(CpfValidator.isValid(null), isFalse);
    });

    test(
      'CNPJ verifica os dígitos e aceita o exemplo alfanumérico oficial',
      () {
        expect(CnpjValidator.isValid('11.222.333/0001-81'), isTrue);
        expect(CnpjValidator.isValid('11.222.333/0001-80'), isFalse);
        expect(CnpjValidator.isValid('12.ABC.345/01DE-35'), isTrue);
      },
    );

    test('CEP valida somente a forma de oito dígitos', () {
      expect(CepValidator.hasValidShape('01001-000'), isTrue);
      expect(CepValidator.hasValidShape('0100'), isFalse);
    });

    test('UF aceita siglas brasileiras sem diferenciar caixa', () {
      expect(UfValidator.isValid('sp'), isTrue);
      expect(UfValidator.isValid('XX'), isFalse);
    });

    test('telefone aceita números nacionais com 10 ou 11 dígitos', () {
      expect(PhoneBrValidator.hasValidShape('(11) 2345-6789'), isTrue);
      expect(PhoneBrValidator.hasValidShape('(11) 92345-6789'), isTrue);
      expect(PhoneBrValidator.hasValidShape('123456789'), isFalse);
    });
  });

  group('formatação de texto', () {
    test('formata documentos completos e preserva entrada inválida', () {
      expect(formatCpf('52998224725'), '529.982.247-25');
      expect(formatCpf('123'), '123');
      expect(formatCnpj('12ABC34501DE35'), '12.ABC.345/01DE-35');
      expect(formatCep('01001000'), '01001-000');
      expect(formatPhoneBr('11923456789'), '(11) 92345-6789');
    });
  });
}

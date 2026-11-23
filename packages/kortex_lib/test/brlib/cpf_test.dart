import 'package:kortex_lib/kortex_lib.dart';
import 'package:test/test.dart';

void main() {
  group('Cpf Extension Type', () {
    const cpfValido = '52998224725';
    const cpfFormatado = '529.982.247-25';

    test('parse limpa caracteres não numéricos', () {
      final cpf = Cpf.parse(cpfFormatado);
      expect(cpf.value, cpfValido);
      expect(cpf.masked, cpfFormatado);
      expect(cpf.formatted, cpfFormatado);
      expect(cpf.isValid, isTrue);
    });

    test('tryParse valida e retorna CpfParseResult com sucesso', () {
      final res = Cpf.tryParse(cpfFormatado);
      expect(res.isSuccess, isTrue);
      expect(res.isFailure, isFalse);
      expect(res.getOrNull()?.value, cpfValido);
    });

    test('tryParse rejeita CPF inválido ou nulo', () {
      final resInvalido = Cpf.tryParse('111.111.111-11');
      expect(resInvalido.isSuccess, isFalse);
      expect(resInvalido.isFailure, isTrue);
      expect(resInvalido.getOrNull(), isNull);

      final resNull = Cpf.tryParse(null);
      expect(resNull.isSuccess, isFalse);
    });

    test('igualdade por valor', () {
      final cpf1 = Cpf(cpfValido);
      final cpf2 = Cpf.parse(cpfFormatado);
      expect(cpf1, equals(cpf2));
    });
  });
}

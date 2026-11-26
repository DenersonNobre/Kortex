import 'package:kortex_core/kortex_core.dart';
import 'package:test/test.dart';

void main() {
  group('Email VO', () {
    test('normaliza para minúsculas e valida formato', () {
      final email = Email('Usuario.Teste@Dominio.COM.br');
      expect(email.valor, 'usuario.teste@dominio.com.br');
      expect(email.toString(), 'usuario.teste@dominio.com.br');
    });

    test('rejeita e-mails inválidos com FormatException', () {
      expect(() => Email('invalido'), throwsA(isA<FormatException>()));
      expect(() => Email(''), throwsA(isA<FormatException>()));
      expect(() => Email('@sem-usuario.com'), throwsA(isA<FormatException>()));
    });

    test('valido e tryParse funcionam sem exceção', () {
      expect(Email.valido('teste@teste.com'), isTrue);
      expect(Email.valido('invalido'), isFalse);
      expect(Email.tryParse('teste@teste.com')?.valor, 'teste@teste.com');
      expect(Email.tryParse('invalido'), isNull);
    });

    test('igualdade estrutural', () {
      final e1 = Email('a@b.com');
      final e2 = Email('A@B.COM');
      expect(e1, equals(e2));
    });
  });

  group('Senha VO', () {
    test('aceita senha com 6 ou mais caracteres e mascara no toString', () {
      final senha = Senha('segredo123');
      expect(senha.valor, 'segredo123');
      expect(senha.toString(), 'senha: ****');
    });

    test('rejeita senha com menos de 6 caracteres', () {
      expect(() => Senha('12345'), throwsA(isA<FormatException>()));
    });

    test('valido e tryParse funcionam', () {
      expect(Senha.valido('123456'), isTrue);
      expect(Senha.valido('12345'), isFalse);
      expect(Senha.tryParse('123456')?.valor, '123456');
      expect(Senha.tryParse('12345'), isNull);
    });

    test('igualdade estrutural', () {
      final s1 = Senha('minhasenha');
      final s2 = Senha('minhasenha');
      expect(s1, equals(s2));
    });
  });
}

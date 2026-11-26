import 'package:kortex_core/kortex_core.dart';
import 'package:test/test.dart';

void main() {
  group('SecretCipher', () {
    const segredo = 'chave-ultra-secreta-de-teste-12345';
    const cipher = SecretCipher(segredo);

    test('hasSecret retorna true para chave preenchida e false para vazia', () {
      expect(cipher.hasSecret(), isTrue);
      expect(const SecretCipher('').hasSecret(), isFalse);
    });

    test(
      'cifra e decifra texto corretamente preservando o conteudo original',
      () {
        const original = 'senhaSuperSecreta@2026';
        final cifrado = cipher.encrypt(original);

        expect(cifrado, isNot(equals(original)));
        expect(cifrado, contains(':'));

        final decifrado = cipher.decrypt(cifrado);
        expect(decifrado, original);
      },
    );

    test('gera IVs aleatórios diferentes para o mesmo texto plano', () {
      const texto = 'mesmoTexto';
      final cifrado1 = cipher.encrypt(texto);
      final cifrado2 = cipher.encrypt(texto);

      expect(cifrado1, isNot(equals(cifrado2)));
      expect(cipher.decrypt(cifrado1), texto);
      expect(cipher.decrypt(cifrado2), texto);
    });

    test('lanca FormatException para formato invalido na decifracao', () {
      expect(
        () => cipher.decrypt('texto-sem-separador-valido'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:kortex_lib/kortex_lib.dart';

void main() {
  group('Document (extension type - Zero Cost Abstraction)', () {
    test('normaliza CPF com máscara através do factory parse', () {
      final doc = Document.parse('529.982.247-25');
      expect(doc.value, equals('52998224725'));
      expect(doc.isEmpty, isFalse);
      expect(doc.isCpf, isTrue);
      expect(doc.isCnpj, isFalse);
      expect(doc.isValid, isTrue);
      expect(doc.formatted, equals('529.982.247-25'));
    });

    test('normaliza CNPJ com máscara através do factory parse', () {
      final doc = Document.parse('11.222.333/0001-81');
      expect(doc.value, equals('11222333000181'));
      expect(doc.isCpf, isFalse);
      expect(doc.isCnpj, isTrue);
      expect(doc.isValid, isTrue);
      expect(doc.formatted, equals('11.222.333/0001-81'));
    });

    test('identifica documento inválido (dígitos ou tamanho)', () {
      final cpfInvalido = Document.parse('111.111.111-11');
      expect(cpfInvalido.isValid, isFalse);
      expect(cpfInvalido.formatted, equals('11111111111'));

      final curto = Document.parse('123');
      expect(curto.isValid, isFalse);
      expect(curto.isCpf, isFalse);
      expect(curto.isCnpj, isFalse);

      const vazio = Document('');
      expect(vazio.isEmpty, isTrue);
      expect(vazio.isValid, isFalse);
    });

    test('mantém valor puro quando instanciado const diretamente', () {
      const doc = Document('52998224725');
      expect(doc.value, equals('52998224725'));
      expect(doc.isValid, isTrue);
      expect(doc.formatted, equals('529.982.247-25'));
    });
  });
}

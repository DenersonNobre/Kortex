import 'package:kortex_lib/brlib/brlib.dart';
import 'package:test/test.dart';

void main() {
  group('Endereco', () {
    test('isVazio é true quando todos os campos são nulos', () {
      const endereco = Endereco();
      expect(endereco.isVazio, isTrue);
    });

    test('isVazio é false quando ao menos um campo é preenchido', () {
      const endereco = Endereco(cidade: 'Curitiba');
      expect(endereco.isVazio, isFalse);
    });

    test('fromColumns lê chaves UPPER e descarta strings em branco', () {
      final mapa = {
        'CEP': ' 80000-000 ',
        'BAIRRO': 'Centro',
        'CIDADE': 'Curitiba',
        'ESTADO': 'PR',
        'ENDERECO': 'Rua das Flores',
        'NUMERO': ' 100 ',
        'COMPLEMENTO': '   ',
      };
      final endereco = Endereco.fromColumns(mapa);
      expect(endereco.cep, '80000-000');
      expect(endereco.bairro, 'Centro');
      expect(endereco.cidade, 'Curitiba');
      expect(endereco.estado, 'PR');
      expect(endereco.logradouro, 'Rua das Flores');
      expect(endereco.numero, '100');
      expect(endereco.complemento, isNull);
      expect(endereco.isVazio, isFalse);
    });

    test('toColumns projeta para formato de colunas de banco de dados', () {
      const endereco = Endereco(
        cep: '80000-000',
        bairro: 'Centro',
        cidade: 'Curitiba',
        estado: 'PR',
        logradouro: 'Rua XV',
        numero: '10',
      );
      final cols = endereco.toColumns();
      expect(cols['CEP'], '80000-000');
      expect(cols['BAIRRO'], 'Centro');
      expect(cols['CIDADE'], 'Curitiba');
      expect(cols['ESTADO'], 'PR');
      expect(cols['ENDERECO'], 'Rua XV');
      expect(cols['NUMERO'], '10');
      expect(cols['COMPLEMENTO'], isNull);
    });

    test('copyWith atualiza apenas campos especificados', () {
      const endereco = Endereco(cidade: 'Curitiba', estado: 'PR');
      final modificado = endereco.copyWith(numero: '20');
      expect(modificado.cidade, 'Curitiba');
      expect(modificado.estado, 'PR');
      expect(modificado.numero, '20');
    });

    test('igualdade e hashCode', () {
      const e1 = Endereco(cidade: 'SP', estado: 'SP');
      const e2 = Endereco(cidade: 'SP', estado: 'SP');
      const e3 = Endereco(cidade: 'RJ', estado: 'RJ');
      expect(e1, equals(e2));
      expect(e1.hashCode, equals(e2.hashCode));
      expect(e1, isNot(equals(e3)));
    });

    test('toString formata endereco legível', () {
      const vazio = Endereco();
      expect(vazio.toString(), 'Endereco.vazio');

      const completo = Endereco(
        logradouro: 'Av Paulista',
        numero: '1000',
        complemento: 'Apto 10',
        bairro: 'Bela Vista',
        cidade: 'São Paulo',
        estado: 'SP',
        cep: '01310-100',
      );
      expect(
        completo.toString(),
        'Av Paulista, 1000 - Apto 10 - Bela Vista - São Paulo/SP - CEP 01310-100',
      );
    });
  });
}

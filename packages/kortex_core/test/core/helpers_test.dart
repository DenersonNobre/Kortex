import 'package:kortex_core/core/core.dart';
import 'package:test/test.dart';

void main() {
  group('KeyValue', () {
    test('tem igualdade por chave e valor', () {
      expect(
        const KeyValue(key: 'id', value: '42'),
        const KeyValue(key: 'id', value: '42'),
      );
      expect(
        const KeyValue(key: 'id', value: '42'),
        isNot(const KeyValue(key: 'id', value: '43')),
      );
    });
  });

  group('Paginate', () {
    test('preserva take/skip em round-trip JSON', () {
      final paginate = Paginate(take: 10, skip: 20);
      final restored = Paginate.fromJson(paginate.toJson());

      expect(restored, paginate);
    });

    test('converte valores numéricos recebidos como string', () {
      final paginate = Paginate.fromMap({'take': '5', 'skip': 2});

      expect(paginate.take, 5);
      expect(paginate.skip, 2);
    });

    test('é imutável e serve como chave de Map', () {
      const paginate = Paginate(take: 10, skip: 20);
      final map = {paginate: 'pagina'};

      expect(map[const Paginate(take: 10, skip: 20)], equals('pagina'));
    });
  });

  group('Query', () {
    test('permite filtro e paginação opcionais', () {
      const query = Query();
      expect(query.filter, isNull);
      expect(query.paginate, isNull);

      final filtered = Query(
        filter: const Filter({'name': 'Ada'}),
        paginate: Paginate(take: 5, skip: 2),
      );
      expect(filtered.filter?.fields, {'name': 'Ada'});
      expect(filtered.paginate?.take, 5);
      expect(filtered.paginate?.skip, 2);
    });
  });
}

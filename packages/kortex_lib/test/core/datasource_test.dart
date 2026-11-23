import 'package:kortex_lib/core/core.dart';
import 'package:test/test.dart';

class _ReadOnlyDataSource implements IReadAllDataSource {
  @override
  Future<IResult<List<Map<String, dynamic>>, IFailure>> readAll(
    Query? query,
  ) async => Success([
    {'name': 'A'},
  ]);
}

class _CrudDataSource implements ICrudDataSource {
  @override
  final String resource = 'table';

  final created = <Map<String, dynamic>>[];

  @override
  Future<IResult<Object?, IFailure>> create(Map<String, dynamic> map) async {
    created.add(map);
    return Success(created.length);
  }

  @override
  Future<IResult<List<Map<String, dynamic>>, IFailure>> readAll(
    Query? query,
  ) async => Success(created);

  @override
  Future<IResult<Map<String, dynamic>?, IFailure>> readById(
    KeyValue keyValue,
  ) async {
    final matches = created.where((row) => row[keyValue.key] == keyValue.value);
    return Success(matches.isEmpty ? null : matches.first);
  }

  @override
  Future<IResult<Object?, IFailure>> update(
    KeyValue keyValue,
    Map<String, dynamic> map,
  ) async => Success(1);

  @override
  Future<IResult<Object?, IFailure>> delete(KeyValue keyValue) async =>
      Success(1);
}

void main() {
  test('portas permitem implementar só a leitura', () async {
    final result = await _ReadOnlyDataSource().readAll(null);
    expect(result.getOrNull(), [
      {'name': 'A'},
    ]);
  });

  test(
    'contrato CRUD usa recurso, mapas, chave e consulta via IResult',
    () async {
      final source = _CrudDataSource();
      expect(source.resource, 'table');

      final created = await source.create({'id': '1', 'name': 'A'});
      expect(created.getOrNull(), 1);

      final rows = await source.readAll(null);
      expect(rows.getOrNull(), [
        {'id': '1', 'name': 'A'},
      ]);

      final byId = await source.readById(const KeyValue(key: 'id', value: '1'));
      expect(byId.getOrNull(), {'id': '1', 'name': 'A'});
    },
  );

  test('readById devolve Success(null) para registro ausente', () async {
    final source = _CrudDataSource();
    final missing = await source.readById(
      const KeyValue(key: 'id', value: 'x'),
    );
    expect(missing.isSuccess, isTrue);
    expect(missing.getOrNull(), isNull);
  });
}

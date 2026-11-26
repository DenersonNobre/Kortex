import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kortex_core/core/core.dart'
    show Filter, KeyValue, Paginate, Query;
import 'package:kortex_sqlite/sqlite/sqlite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class ItemReadSource extends ISqliteDataSource with SqliteReadAllResource {
  ItemReadSource(super.sql) : super(resource: 'items');
}

class ItemCrudSource extends ISqliteCrudDataSource {
  ItemCrudSource(super.sql) : super(resource: 'items');
}

/// Resource inexistente para forçar DatabaseException no guard.
class _BrokenSource extends ISqliteCrudDataSource {
  _BrokenSource(super.sql) : super(resource: 'missing_table');
}

void main() {
  late String databaseName;
  late String databasePath;
  late SqliteProvider provider;

  final migrations = [
    Migration(
      version: 1,
      scripts: [
        'CREATE TABLE items ('
            'id INTEGER PRIMARY KEY AUTOINCREMENT, '
            'label TEXT NOT NULL)',
        'CREATE TABLE parents (id INTEGER PRIMARY KEY)',
        'CREATE TABLE children ('
            'id INTEGER PRIMARY KEY, '
            'parent_id INTEGER, '
            'FOREIGN KEY(parent_id) REFERENCES parents(id))',
      ],
    ),
    Migration(
      version: 2,
      scripts: ['CREATE TABLE settings (name TEXT PRIMARY KEY, value TEXT)'],
    ),
  ];

  SqliteProvider newProvider({
    int version = 1,
    List<Migration>? schemaMigrations,
  }) {
    return SqliteProvider(
      dbName: databaseName,
      dbVersion: version,
      migrations: schemaMigrations ?? migrations,
      factory: databaseFactoryFfi,
    );
  }

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    databaseName = 'dnolib_${DateTime.now().microsecondsSinceEpoch}.db';
    databasePath =
        '${await databaseFactoryFfi.getDatabasesPath()}/$databaseName';
    provider = newProvider();
  });

  tearDown(() async {
    await provider.close();
    await databaseFactoryFfi.deleteDatabase(databasePath);
  });

  test('abre sob demanda e permite reabrir após close', () async {
    expect(File(databasePath).existsSync(), isFalse);
    await provider.close();
    expect(File(databasePath).existsSync(), isFalse);

    await provider.db;
    expect(File(databasePath).existsSync(), isTrue);
    await provider.close();
    await provider.db;
    expect(await provider.tableExists('items'), isTrue);
  });

  test(
    'aplica migrações em ordem crescente mesmo se a lista vier fora de ordem',
    () async {
      final orderedMigrations = [
        Migration(
          version: 2,
          scripts: ["INSERT INTO ordered_table (value) VALUES ('v2')"],
        ),
        Migration(
          version: 1,
          scripts: ['CREATE TABLE ordered_table (value TEXT NOT NULL)'],
        ),
      ];
      provider = newProvider(version: 2, schemaMigrations: orderedMigrations);

      await provider.db;

      expect(await provider.count('ordered_table'), 1);
    },
  );

  test('aplica somente migrations novas durante upgrade', () async {
    await provider.db;
    await provider.close();
    provider = newProvider(version: 2);

    await provider.db;

    expect(await provider.tableExists('items'), isTrue);
    expect(await provider.tableExists('settings'), isTrue);
  });

  test('habilita foreign keys e bloqueia referência inexistente', () async {
    final database = await provider.db;

    await expectLater(
      database.insert('children', {'parent_id': 404}),
      throwsA(isA<DatabaseException>()),
    );
  });

  test(
    'count, tableInfo e tableExists funcionam e tratam identificadores como dados',
    () async {
      final database = await provider.db;
      await database.insert('items', {'label': 'one'});
      await database.insert('items', {'label': 'two'});

      expect(await provider.count('items'), 2);
      expect(await provider.tableExists('missing'), isFalse);
      expect(
        (await provider.tableInfo('items')).map((column) => column['name']),
        containsAll(['id', 'label']),
      );
      expect(
        await provider.tableExists('items"; DROP TABLE items; --'),
        isFalse,
      );
      expect(await provider.count('items'), 2);
    },
  );

  test('migrações rejeitam versões inválidas ou duplicadas', () {
    expect(() => Migration(version: 0, scripts: const []), throwsArgumentError);
    expect(
      () => SqliteProvider(
        dbName: databaseName,
        dbVersion: 1,
        migrations: [
          Migration(version: 1, scripts: const []),
          Migration(version: 1, scripts: const []),
        ],
        factory: databaseFactoryFfi,
      ),
      throwsArgumentError,
    );
  });

  test(
    'read-only datasource aplica filtro e paginação sem exigir CRUD',
    () async {
      final database = await provider.db;
      for (final label in ['A', 'B', 'B']) {
        await database.insert('items', {'label': label});
      }
      final source = ItemReadSource(provider);

      final result = await source.readAll(
        Query(
          filter: Filter({'label': 'B'}),
          paginate: Paginate(take: 1, skip: 1),
        ),
      );

      final rows = result.getOrNull()!;
      expect(rows, hasLength(1));
      expect(rows.single['label'], 'B');
    },
  );

  test(
    'CRUD datasource usa valores parametrizados e chaves genéricas',
    () async {
      final source = ItemCrudSource(provider);
      final id = (await source.create({'label': "A' OR 1=1 --"})).getOrNull()!;
      final key = KeyValue(key: 'id', value: '$id');

      expect(
        (await source.readById(key)).getOrNull()?['label'],
        "A' OR 1=1 --",
      );
      expect((await source.update(key, {'label': 'changed'})).getOrNull(), 1);
      expect((await source.readById(key)).getOrNull()?['label'], 'changed');
      expect((await source.delete(key)).getOrNull(), 1);
      final missing = await source.readById(key);
      expect(missing.isSuccess, isTrue);
      expect(missing.getOrNull(), isNull);
    },
  );

  test('falha de banco vira InfrastructureFailure, não exceção', () async {
    final source = ItemCrudSource(provider);
    // Tabela inexistente → DatabaseException capturado como Failure.
    final result = await source.readById(const KeyValue(key: 'id', value: '1'));
    // 'items' existe; força erro com resource inválido via mixin separado.
    final broken = _BrokenSource(provider);
    final brokenResult = await broken.readAll(null);
    expect(brokenResult.isFailure, isTrue);
    expect(brokenResult.getOrNullFailure()?.code, 'INFRASTRUCTURE_ERROR');
    expect(result.isSuccess, isTrue);
  });

  test('unit of work confirma operações e conta consultas', () async {
    await provider.inTransaction((unitOfWork) async {
      await unitOfWork.insert('items', {'label': 'inside'});
      expect(await unitOfWork.rawCount('SELECT COUNT(*) FROM items'), 1);
      await unitOfWork.update(
        'items',
        {'label': 'updated'},
        where: 'label = ?',
        whereArgs: ['inside'],
      );
    });

    expect(await provider.count('items'), 1);
  });

  test('unit of work faz rollback quando a operação falha', () async {
    await expectLater(
      provider.inTransaction((unitOfWork) async {
        await unitOfWork.insert('items', {'label': 'temporary'});
        throw StateError('rollback');
      }),
      throwsStateError,
    );

    expect(await provider.count('items'), 0);
  });
}

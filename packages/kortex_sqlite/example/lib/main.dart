import 'package:kortex_sqlite/kortex_sqlite.dart';

/// Exemplo didático completo do `kortex_sqlite`:
/// 1. Migrações versionadas (`Migration`)
/// 2. Provedor de banco (`SqliteProvider`)
/// 3. Transação atômica (`SqliteUnitOfWork`)
Future<void> main() async {
  final provider = SqliteProvider(
    dbName: 'kortex_example.db',
    dbVersion: 2,
    migrations: [
      Migration(
        version: 1,
        scripts: [
          'CREATE TABLE IF NOT EXISTS items (id TEXT PRIMARY KEY, name TEXT NOT NULL)',
        ],
      ),
      Migration(
        version: 2,
        scripts: [
          'ALTER TABLE items ADD COLUMN active INTEGER NOT NULL DEFAULT 1',
        ],
      ),
    ],
  );

  // Em runtime Flutter (Android/iOS/Desktop), execute transações atômicas assim:
  // await provider.runInTransaction((uow) async {
  //   await uow.insert('items', {'id': '1', 'name': 'Visita Tecnica', 'active': 1});
  //   await uow.update('items', {'active': 0}, where: 'id = ?', whereArgs: ['1']);
  // });
  // await provider.close();

  print(
    'SqliteProvider "${provider.dbName}" v${provider.dbVersion} '
    'configurado com ${provider.migrations.length} migracoes.',
  );
}

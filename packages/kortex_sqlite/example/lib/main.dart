import 'package:kortex_sqlite/kortex_sqlite.dart';

/// Exemplo didático de migrações versionadas e configuração do `kortex_sqlite`.
void main() {
  final migrations = [
    Migration(
      version: 1,
      scripts: [
        'CREATE TABLE IF NOT EXISTS items (id TEXT PRIMARY KEY, name TEXT NOT NULL)',
      ],
    ),
    Migration(
      version: 2,
      scripts: [
        'ALTER TABLE items ADD COLUMN created_at TEXT',
      ],
    ),
  ];

  for (final migration in migrations) {
    print(
      'Migration v${migration.version}: ${migration.scripts.length} script(s)',
    );
  }
}

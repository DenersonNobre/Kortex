import 'package:kortex_sqlite/kortex_sqlite.dart';

/// Exemplo didático de definição de migração versionada com `kortex_sqlite`.
void main() {
  final migrationV1 = Migration(
    version: 1,
    scripts: [
      'CREATE TABLE IF NOT EXISTS items (id TEXT PRIMARY KEY, name TEXT NOT NULL)',
    ],
  );

  print(
    'Migração v${migrationV1.version} pronta com ${migrationV1.scripts.length} script(s).',
  );
}

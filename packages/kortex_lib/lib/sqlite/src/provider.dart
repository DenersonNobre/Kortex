import 'package:sqflite/sqflite.dart';

import 'migration.dart';
import 'unit_of_work.dart';

class SqliteProvider {
  SqliteProvider({
    required this.dbName,
    required this.dbVersion,
    required List<Migration> migrations,
    DatabaseFactory? factory,
    this._onConfigure,
  }) : migrations = List.unmodifiable(migrations),
       _factory = factory ?? databaseFactory {
    if (dbVersion < 1) {
      throw ArgumentError.value(
        dbVersion,
        'dbVersion',
        'Deve ser maior que zero.',
      );
    }
    final versions = this.migrations.map((migration) => migration.version);
    if (versions.toSet().length != versions.length) {
      throw ArgumentError('Cada migration precisa ter uma versão única.');
    }
  }

  final String dbName;
  final int dbVersion;
  final List<Migration> migrations;
  final DatabaseFactory _factory;
  final Future<void> Function(Database database)? _onConfigure;

  Future<Database>? _dbCache;

  Future<Database> get db => _dbCache ??= _open();

  Future<Database> _open() async {
    try {
      final path = '${await _factory.getDatabasesPath()}/$dbName';
      return await _factory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: dbVersion,
          onConfigure: _configure,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
    } catch (_) {
      _dbCache = null;
      rethrow;
    }
  }

  Future<void> _configure(Database database) async {
    await database.execute('PRAGMA foreign_keys = ON');
    await _onConfigure?.call(database);
  }

  Future<void> close() async {
    final cached = _dbCache;
    if (cached == null) return;
    final database = await cached;
    await database.close();
    if (identical(_dbCache, cached)) _dbCache = null;
  }

  Future<T> inTransaction<T>(
    Future<T> Function(SqliteUnitOfWork unitOfWork) action,
  ) async {
    final database = await db;
    return database.transaction(
      (transaction) => action(SqliteUnitOfWork(transaction)),
    );
  }

  Future<int?> count(String table) async {
    final database = await db;
    final quotedTable = _quoteIdentifier(table);
    return Sqflite.firstIntValue(
      await database.rawQuery('SELECT COUNT(*) FROM $quotedTable'),
    );
  }

  Future<List<Map<String, Object?>>> tableInfo(String table) async {
    final database = await db;
    final quotedTable = _quoteIdentifier(table);
    return database.rawQuery('PRAGMA table_info($quotedTable)');
  }

  Future<bool> tableExists(String table) async =>
      (await tableInfo(table)).isNotEmpty;

  Future<void> _runMigrations(
    Database database,
    Iterable<Migration> migrationsToRun,
  ) async {
    final ordered = migrationsToRun.toList()
      ..sort((left, right) => left.version.compareTo(right.version));
    for (final migration in ordered) {
      for (final script in migration.scripts) {
        await database.execute(script);
      }
    }
  }

  Future<void> _onCreate(Database database, int version) {
    return _runMigrations(
      database,
      migrations.where((migration) => migration.version <= version),
    );
  }

  Future<void> _onUpgrade(Database database, int oldVersion, int newVersion) {
    return _runMigrations(
      database,
      migrations.where(
        (migration) =>
            migration.version > oldVersion && migration.version <= newVersion,
      ),
    );
  }
}

String _quoteIdentifier(String identifier) =>
    '"${identifier.replaceAll('"', '""')}"';

import 'package:sqflite/sqflite.dart';

class SqliteUnitOfWork {
  SqliteUnitOfWork(this._transaction);

  final Transaction _transaction;

  Future<int> insert(String table, Map<String, Object?> values) {
    return _transaction.insert(table, values);
  }

  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
  }) {
    return _transaction.update(
      table,
      values,
      where: where,
      whereArgs: whereArgs,
    );
  }

  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) {
    return _transaction.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<List<Map<String, Object?>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) {
    return _transaction.rawQuery(sql, arguments);
  }

  Future<int> rawCount(String sql, [List<Object?>? arguments]) async {
    final rows = await _transaction.rawQuery(sql, arguments);
    if (rows.isEmpty || rows.first.isEmpty) return 0;
    final value = rows.first.values.first;
    if (value is int) return value;
    throw StateError('A consulta de contagem não retornou um inteiro.');
  }
}

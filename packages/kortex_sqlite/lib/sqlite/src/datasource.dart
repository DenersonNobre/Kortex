import 'package:kortex_core/core/core.dart'
    show
        ICreateDataSource,
        IDataSource,
        IDeleteDataSource,
        IReadAllDataSource,
        IReadByIdDataSource,
        ICrudDataSource,
        IFailure,
        IResult,
        IUpdateDataSource,
        InfrastructureFailure,
        KeyValue,
        Query,
        Success,
        Failure;

import 'provider.dart';

abstract class ISqliteDataSource extends IDataSource {
  ISqliteDataSource(this.sql, {required super.resource});

  final SqliteProvider sql;

  /// Wraps a raw sqflite call so [DatabaseException] and I/O errors flow
  /// as [InfrastructureFailure] through [IResult].
  Future<IResult<T, IFailure>> guard<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } catch (error) {
      return Failure(InfrastructureFailure('SQLite [$resource]: $error'));
    }
  }
}

abstract class ISqliteCrudDataSource extends ISqliteDataSource
    with
        SqliteCreateResource,
        SqliteReadAllResource,
        SqliteReadByIdResource,
        SqliteUpdateResource,
        SqliteDeleteResource
    implements ICrudDataSource {
  ISqliteCrudDataSource(super.sql, {required super.resource});
}

//...

mixin SqliteCreateResource on ISqliteDataSource implements ICreateDataSource {
  @override
  Future<IResult<Object?, IFailure>> create(Map<String, dynamic> map) {
    return guard(() async {
      final database = await sql.db;
      return database.insert(_quoteIdentifier(resource), map);
    });
  }
}

mixin SqliteReadAllResource on ISqliteDataSource implements IReadAllDataSource {
  @override
  Future<IResult<List<Map<String, dynamic>>, IFailure>> readAll(Query? query) {
    return guard(() async {
      final filter = query?.filter;
      final fields = filter?.fields;
      return (await (await sql.db).query(
        _quoteIdentifier(resource),
        where: _where(fields),
        whereArgs: _arguments(fields),
        limit: query?.paginate?.take,
        offset: query?.paginate?.skip,
      ));
    });
  }

  String? _where(Map<String, dynamic>? fields) {
    if (fields == null || fields.isEmpty) return null;
    return fields.keys
        .map((key) => '${_quoteIdentifier(key)} = ?')
        .join(' AND ');
  }

  List<Object?>? _arguments(Map<String, dynamic>? fields) {
    if (fields == null || fields.isEmpty) return null;
    return fields.values.toList();
  }
}

mixin SqliteReadByIdResource on ISqliteDataSource
    implements IReadByIdDataSource {
  @override
  Future<IResult<Map<String, dynamic>?, IFailure>> readById(KeyValue keyValue) {
    return guard(() async {
      final rows = await (await sql.db).query(
        _quoteIdentifier(resource),
        where: '${_quoteIdentifier(keyValue.key)} = ?',
        whereArgs: [keyValue.value],
        limit: 1,
      );
      return rows.isEmpty ? null : rows.first;
    });
  }
}

mixin SqliteUpdateResource on ISqliteDataSource implements IUpdateDataSource {
  @override
  Future<IResult<Object?, IFailure>> update(
    KeyValue keyValue,
    Map<String, dynamic> map,
  ) {
    return guard(() async {
      return (await sql.db).update(
        _quoteIdentifier(resource),
        map,
        where: '${_quoteIdentifier(keyValue.key)} = ?',
        whereArgs: [keyValue.value],
      );
    });
  }
}

mixin SqliteDeleteResource on ISqliteDataSource implements IDeleteDataSource {
  @override
  Future<IResult<Object?, IFailure>> delete(KeyValue keyValue) {
    return guard(() async {
      return (await sql.db).delete(
        _quoteIdentifier(resource),
        where: '${_quoteIdentifier(keyValue.key)} = ?',
        whereArgs: [keyValue.value],
      );
    });
  }
}

String _quoteIdentifier(String identifier) =>
    '"${identifier.replaceAll('"', '""')}"';

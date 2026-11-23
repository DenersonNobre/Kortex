import 'package:kortex_lib/core/core.dart'
    show
        ICreateDataSource,
        IDataSource,
        IDeleteDataSource,
        IReadAllDataSource,
        IReadByIdDataSource,
        ICrudDataSource,
        ConflictFailure,
        IFailure,
        IResult,
        IUpdateDataSource,
        InfrastructureFailure,
        KeyValue,
        NotFoundFailure,
        Query,
        Success,
        Failure,
        UnauthorizedFailure;

import 'client.dart';

abstract class IRestDataSource extends IDataSource {
  IRestDataSource(this.config, this.api, {required super.resource});

  final RestConfig config;
  final RestClient api;
}

/// Maps HTTP transport errors to a typed [IFailure] so they flow through
/// the same [IResult] monad as domain failures.
///
/// Status with domain meaning map to the matching [FailureCode] subtype
/// (401→unauthorized, 404→not found, 409→conflict); anything else stays
/// an [InfrastructureFailure]. Closes the [FailureCode] contract: the
/// taxonomy is emitted, not just offered.
IFailure restFailure(RestResponse response) {
  final message =
      'HTTP ${response.statusCode ?? 'transport'}: ${response.statusText.isEmpty ? 'request failed' : response.statusText}';
  return switch (response.statusCode) {
    401 => UnauthorizedFailure(message, response.statusCode),
    404 => NotFoundFailure(message, response.statusCode),
    409 => ConflictFailure(message, response.statusCode),
    _ => InfrastructureFailure(message, response.statusCode),
  };
}

Map<String, dynamic> buildQueryParams(Query? query) {
  final params = <String, dynamic>{};
  final pagination = query?.paginate;
  if (pagination != null) params.addAll(pagination.toMap());
  final fields = query?.filter?.fields;
  if (fields != null) params.addAll(fields);
  return params.map((key, value) => MapEntry(key, '$value'));
}

mixin RestCreateResource on IRestDataSource implements ICreateDataSource {
  @override
  Future<IResult<Object?, IFailure>> create(Map<String, dynamic> map) async {
    final response = await api.post('/$resource', map);
    if (response.hasError) return Failure(restFailure(response));
    return Success(response.body);
  }
}

mixin RestReadAllResource on IRestDataSource implements IReadAllDataSource {
  @override
  Future<IResult<List<Map<String, dynamic>>, IFailure>> readAll(
    Query? query,
  ) async {
    final response = await api.get(
      '/$resource',
      query: buildQueryParams(query),
    );
    if (response.hasError) return Failure(restFailure(response));
    final body = response.body;
    if (body is! List) {
      return Failure(
        InfrastructureFailure('Response body for $resource is not a list.'),
      );
    }
    try {
      return Success(
        body.map((record) => Map<String, dynamic>.from(record as Map)).toList(),
      );
    } on TypeError {
      return Failure(
        InfrastructureFailure(
          'Response body for $resource contains a non-object record.',
        ),
      );
    }
  }
}

mixin RestReadByIdResource on IRestDataSource implements IReadByIdDataSource {
  @override
  Future<IResult<Map<String, dynamic>?, IFailure>> readById(
    KeyValue keyValue,
  ) async {
    final response = await api.get(
      '/$resource/${Uri.encodeComponent(keyValue.value)}',
    );
    if (response.statusCode == 404) return Success(null);
    if (response.hasError) return Failure(restFailure(response));
    final body = response.body;
    if (body is Map) return Success(Map<String, dynamic>.from(body));
    return Success(null);
  }
}

mixin RestUpdateResource on IRestDataSource implements IUpdateDataSource {
  @override
  Future<IResult<Object?, IFailure>> update(
    KeyValue keyValue,
    Map<String, dynamic> map,
  ) async {
    final response = await api.put(
      '/$resource/${Uri.encodeComponent(keyValue.value)}',
      map,
    );
    if (response.hasError) return Failure(restFailure(response));
    return Success(response.body);
  }
}

/// Porta REST de atualização parcial (PATCH — RFC 5789). Vive no módulo de
/// transporte porque PATCH é semântica HTTP sem análogo em banco; a porta de
/// update do `core` cobre o mapa parcial genérico.
abstract class IRestPatchDataSource {
  Future<IResult<Object?, IFailure>> patch(
    KeyValue keyValue,
    Map<String, dynamic> map,
  );
}

mixin RestPatchResource on IRestDataSource implements IRestPatchDataSource {
  @override
  Future<IResult<Object?, IFailure>> patch(
    KeyValue keyValue,
    Map<String, dynamic> map,
  ) async {
    final response = await api.patch(
      '/$resource/${Uri.encodeComponent(keyValue.value)}',
      map,
    );
    if (response.hasError) return Failure(restFailure(response));
    return Success(response.body);
  }
}

mixin RestDeleteResource on IRestDataSource implements IDeleteDataSource {
  @override
  Future<IResult<Object?, IFailure>> delete(KeyValue keyValue) async {
    final response = await api.delete(
      '/$resource/${Uri.encodeComponent(keyValue.value)}',
    );
    if (response.hasError) return Failure(restFailure(response));
    return Success(response.body);
  }
}

abstract class IRestCrudDataSource extends IRestDataSource
    with
        RestCreateResource,
        RestReadAllResource,
        RestReadByIdResource,
        RestUpdateResource,
        RestPatchResource,
        RestDeleteResource
    implements ICrudDataSource, IRestPatchDataSource {
  IRestCrudDataSource(super.config, super.api, {required super.resource});
}

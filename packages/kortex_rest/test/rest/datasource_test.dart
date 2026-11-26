import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kortex_core/core/core.dart'
    show Filter, KeyValue, Paginate, Query;
import 'package:kortex_rest/rest/rest.dart';

class ReadOnlyItems extends IRestDataSource with RestReadAllResource {
  ReadOnlyItems(super.config, super.api) : super(resource: 'items');
}

class ItemsDataSource extends IRestCrudDataSource {
  ItemsDataSource(super.config, super.api) : super(resource: 'items');
}

void main() {
  const config = RestConfig(baseUrl: 'https://example.test/api');

  RestClient clientWith(http.Client client) =>
      RestClient(config, httpClient: client);

  test('query conversion merges filters and pagination', () {
    final params = buildQueryParams(
      Query(
        filter: const Filter({'active': true}),
        paginate: Paginate(take: 5, skip: 2),
      ),
    );

    expect(params, {'active': 'true', 'take': '5', 'skip': '2'});
    expect(buildQueryParams(null), isEmpty);
  });

  test('read-only adapter maps query and list response', () async {
    Uri? requestedUri;
    final dataSource = ReadOnlyItems(
      config,
      clientWith(
        MockClient((request) async {
          requestedUri = request.url;
          return http.Response('[{"id":1}]', 200);
        }),
      ),
    );

    final result = await dataSource.readAll(
      Query(paginate: Paginate(take: 1, skip: 0)),
    );

    expect(requestedUri!.path, '/api/items');
    expect(requestedUri!.queryParameters, {'take': '1', 'skip': '0'});
    expect(result.getOrNull(), [
      <String, dynamic>{'id': 1},
    ]);
  });

  test('CRUD adapter maps HTTP methods and escapes key values', () async {
    final requests = <http.Request>[];
    final dataSource = ItemsDataSource(
      config,
      clientWith(
        MockClient((request) async {
          requests.add(request);
          if (request.method == 'GET') {
            return http.Response('{"id":"a/b"}', 200);
          }
          if (request.method == 'POST') {
            return http.Response(jsonEncode({'id': 1}), 201);
          }
          if (request.method == 'PUT') return http.Response('', 204);
          return http.Response('', 204);
        }),
      ),
    );

    expect((await dataSource.create({'name': 'sample'})).getOrNull(), {
      'id': 1,
    });
    expect(
      (await dataSource.readById(
        const KeyValue(key: 'id', value: 'a/b'),
      )).getOrNull(),
      {'id': 'a/b'},
    );
    await dataSource.update(const KeyValue(key: 'id', value: 'a/b'), {
      'name': 'changed',
    });
    await dataSource.delete(const KeyValue(key: 'id', value: 'a/b'));

    expect(requests.map((request) => request.method), [
      'POST',
      'GET',
      'PUT',
      'DELETE',
    ]);
    expect(requests[1].url.toString(), contains('/api/items/a%2Fb'));
    expect(jsonDecode(requests[2].body), {'name': 'changed'});
  });

  test(
    '404 readById returns Success(null); other errors become Failure',
    () async {
      final missing = ItemsDataSource(
        config,
        clientWith(MockClient((request) async => http.Response('', 404))),
      );
      final missingResult = await missing.readById(
        const KeyValue(key: 'id', value: 'missing'),
      );
      expect(missingResult.isSuccess, isTrue);
      expect(missingResult.getOrNull(), isNull);

      final failing = ItemsDataSource(
        config,
        clientWith(MockClient((request) async => http.Response('down', 503))),
      );
      final failingResult = await failing.readAll(null);
      expect(failingResult.isFailure, isTrue);
      expect(failingResult.getOrNullFailure()?.code, 'INFRASTRUCTURE_ERROR');
    },
  );

  test('patch sends PATCH to the escaped key and maps the response', () async {
    http.Request? sent;
    final dataSource = ItemsDataSource(
      config,
      clientWith(
        MockClient((request) async {
          sent = request;
          return http.Response('{"id":"a/b"}', 200);
        }),
      ),
    );

    final result = await dataSource.patch(
      const KeyValue(key: 'id', value: 'a/b'),
      {'name': 'changed'},
    );

    expect(sent!.method, 'PATCH');
    expect(sent!.url.toString(), contains('/api/items/a%2Fb'));
    expect(jsonDecode(sent!.body), {'name': 'changed'});
    expect(result.getOrNull(), {'id': 'a/b'});
  });

  test('patch maps HTTP errors to Failure', () async {
    final dataSource = ItemsDataSource(
      config,
      clientWith(MockClient((request) async => http.Response('down', 503))),
    );

    final result = await dataSource.patch(
      const KeyValue(key: 'id', value: '1'),
      {'name': 'x'},
    );

    expect(result.isFailure, isTrue);
    expect(result.getOrNullFailure()?.code, 'INFRASTRUCTURE_ERROR');
  });

  test('restFailure maps status codes to typed FailureCode subtypes', () async {
    Future<String?> codeFor(int status) async {
      final dataSource = ItemsDataSource(
        config,
        clientWith(MockClient((request) async => http.Response('err', status))),
      );
      final result = await dataSource.readAll(null);
      expect(result.isFailure, isTrue);
      return result.getOrNullFailure()?.code;
    }

    expect(await codeFor(401), 'UNAUTHORIZED');
    expect(await codeFor(404), 'NOT_FOUND');
    expect(await codeFor(409), 'CONFLICT');
    expect(await codeFor(503), 'INFRASTRUCTURE_ERROR');
  });
}

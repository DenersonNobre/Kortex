import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kortex_lib/rest/rest.dart';

void main() {
  group('RestClient', () {
    test('builds URL, query parameters, headers, and decodes JSON', () async {
      Uri? requestedUri;
      Map<String, String>? receivedHeaders;
      final client = RestClient(
        const RestConfig(baseUrl: 'https://example.test/api/'),
        httpClient: MockClient((request) async {
          requestedUri = request.url;
          receivedHeaders = request.headers;
          return http.Response('{"ready":true}', 200, reasonPhrase: 'OK');
        }),
        headers: const {'X-Trace': 'trace-1'},
      );

      final response = await client.get(
        'health',
        query: {'tag': 'a b', 'page': 2},
      );

      expect(requestedUri!.path, '/api/health');
      expect(requestedUri!.queryParameters, {'tag': 'a b', 'page': '2'});
      expect(receivedHeaders!['accept'], 'application/json');
      expect(receivedHeaders!['x-trace'], 'trace-1');
      expect(response.body, {'ready': true});
      expect(response.statusText, 'OK');
      expect(response.hasError, isFalse);
      client.close();
    });

    test('decodes text and empty response bodies', () async {
      final client = RestClient(
        const RestConfig(baseUrl: 'https://example.test'),
        httpClient: MockClient((request) async {
          if (request.url.path == '/text') return http.Response('alive', 200);
          return http.Response('', 204);
        }),
      );

      expect((await client.get('/text')).body, 'alive');
      expect((await client.delete('/empty')).body, isNull);
      client.close();
    });

    test('encodes JSON request body and maps transport errors', () async {
      String? requestBody;
      final client = RestClient(
        const RestConfig(baseUrl: 'https://example.test'),
        httpClient: MockClient((request) async {
          requestBody = request.body;
          return http.Response('{"id":4}', 201);
        }),
      );

      final response = await client.post('/items', {'name': 'sample'});

      expect(jsonDecode(requestBody!), {'name': 'sample'});
      expect(response.body, {'id': 4});
      client.close();

      final failingClient = RestClient(
        const RestConfig(baseUrl: 'https://example.test'),
        httpClient: MockClient(
          (request) async => throw http.ClientException('offline'),
        ),
      );
      final failure = await failingClient.get('/items');
      expect(failure.hasError, isTrue);
      expect(failure.statusCode, isNull);
      expect(failure.statusText, contains('offline'));
      // Original exception is preserved for typed handling.
      expect(failure.error, isA<http.ClientException>());
      failingClient.close();
    });

    test(
      'timeout aborts slow request and preserves TimeoutException',
      () async {
        final client = RestClient(
          const RestConfig(
            baseUrl: 'https://example.test',
            timeout: Duration(milliseconds: 50),
          ),
          httpClient: MockClient((request) async {
            await Future<void>.delayed(const Duration(seconds: 5));
            return http.Response('{}', 200);
          }),
        );

        final response = await client.get('/slow');
        expect(response.hasError, isTrue);
        expect(response.statusCode, isNull);
        expect(response.error, isA<TimeoutException>());
        client.close();
      },
    );

    test('null status and 4xx are errors; 3xx is not', () {
      expect(const RestResponse().hasError, isTrue);
      expect(const RestResponse(statusCode: 399).hasError, isFalse);
      expect(const RestResponse(statusCode: 400).hasError, isTrue);
    });

    test('sends PATCH with an encoded JSON body', () async {
      http.Request? sent;
      final client = RestClient(
        const RestConfig(baseUrl: 'https://example.test'),
        httpClient: MockClient((request) async {
          sent = request;
          return http.Response('{"patched":true}', 200);
        }),
      );

      final response = await client.patch('/items/7', {'name': 'novo'});

      expect(sent!.method, 'PATCH');
      expect(sent!.url.path, '/items/7');
      expect(sent!.headers['content-type'], contains('application/json'));
      expect(jsonDecode(sent!.body), {'name': 'novo'});
      expect(response.body, {'patched': true});
      client.close();
    });
    group('charset', () {
      Future<Object?> bodyFor(List<int> bytes, String? contentType) async {
        final client = RestClient(
          const RestConfig(baseUrl: 'https://example.test'),
          httpClient: MockClient(
            (_) async => http.Response.bytes(
              bytes,
              200,
              headers: {'content-type': ?contentType},
            ),
          ),
        );
        final response = await client.get('x');
        client.close();
        return response.body;
      }

      test('decodes iso-8859-1', () async {
        final body = await bodyFor(
          latin1.encode('{"c":"São Paulo"}'),
          'application/json; charset=iso-8859-1',
        );
        expect(body, {'c': 'São Paulo'});
      });

      test('decodes explicit utf-8', () async {
        final body = await bodyFor(
          utf8.encode('{"c":"São"}'),
          'application/json; charset=utf-8',
        );
        expect(body, {'c': 'São'});
      });

      test('falls back to utf-8 without charset', () async {
        final body = await bodyFor(utf8.encode('{"c":"São"}'), null);
        expect(body, {'c': 'São'});
      });

      test('falls back to utf-8 on unknown charset', () async {
        final body = await bodyFor(
          utf8.encode('{"c":"São"}'),
          'application/json; charset=x-desconhecido',
        );
        expect(body, {'c': 'São'});
      });
    });
  });
}

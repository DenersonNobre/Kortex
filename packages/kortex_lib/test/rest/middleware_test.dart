import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kortex_lib/rest/rest.dart';

void main() {
  test('retry does not repeat POST unless explicitly opted in', () async {
    var calls = 0;
    final client = RetryClient(
      MockClient((request) async {
        calls++;
        return http.Response('unavailable', 503);
      }),
      initialDelay: Duration.zero,
    );

    await client.post(Uri.parse('https://example.test/items'), body: '{}');

    expect(calls, 1);
    client.close();
  });

  test(
    'circuit breaker opens after threshold and allows a timed probe',
    () async {
      var now = DateTime.utc(2026, 1, 1);
      var shouldFail = true;
      var calls = 0;
      final client = CircuitBreakerClient(
        MockClient((request) async {
          calls++;
          return shouldFail
              ? http.Response('unavailable', 503)
              : http.Response('ok', 200);
        }),
        failureThreshold: 1,
        resetTimeout: const Duration(seconds: 10),
        clock: () => now,
      );

      await client.get(Uri.parse('https://example.test'));
      expect(client.isOpen, isTrue);
      await expectLater(
        client.get(Uri.parse('https://example.test')),
        throwsA(isA<CircuitOpenException>()),
      );
      expect(calls, 1);

      now = now.add(const Duration(seconds: 11));
      shouldFail = false;
      expect(
        (await client.get(Uri.parse('https://example.test'))).statusCode,
        200,
      );
      expect(client.isOpen, isFalse);
      client.close();
    },
  );

  test('logging omits query strings and user info', () async {
    final logs = <String>[];
    final client = LoggingClient(
      MockClient((request) async => http.Response('ok', 200)),
      logger: logs.add,
    );

    await client.get(
      Uri.parse('https://user:secret@example.test/path?token=private'),
    );

    expect(logs.single, contains('GET https://example.test/path -> 200'));
    expect(logs.single, isNot(contains('secret')));
    expect(logs.single, isNot(contains('private')));
    client.close();
  });

  test('client stack composes retries, circuit breaker, and logging', () async {
    var calls = 0;
    final logs = <String>[];
    final client =
        ClientStack.start(
              MockClient((request) async {
                calls++;
                return calls == 1
                    ? http.Response('unavailable', 503)
                    : http.Response('ok', 200);
              }),
            )
            .retrying(initialDelay: Duration.zero)
            .withCircuitBreaker(failureThreshold: 2)
            .logging(logger: logs.add)
            .build();

    final response = await client.get(Uri.parse('https://example.test'));

    expect(response.statusCode, 200);
    expect(calls, 2);
    // O logging fica DENTRO do retry na ordem canônica, então registra
    // cada tentativa: o 503 que disparou o retry e o 200 final.
    expect(logs, hasLength(2));
    expect(logs.first, contains('503'));
    expect(logs.last, contains('200'));
    client.close();
  });

  test('a ordem das chamadas no ClientStack nao altera o resultado', () async {
    // Contrato: ClientStack compoe em ordem canonica fixa, entao
    // registrar os mesmos decorators em ordens diferentes produz a
    // mesma cadeia e o mesmo log.
    Future<List<String>> compose(List<String> order) async {
      var calls = 0;
      final logs = <String>[];
      final stack = ClientStack.start(
        MockClient((request) async {
          calls++;
          return calls == 1
              ? http.Response('unavailable', 503)
              : http.Response('ok', 200);
        }),
      );

      for (final step in order) {
        switch (step) {
          case 'retry':
            stack.retrying(initialDelay: Duration.zero);
          case 'breaker':
            stack.withCircuitBreaker(failureThreshold: 2);
          case 'logging':
            stack.logging(logger: logs.add);
        }
      }

      final client = stack.build();
      await client.get(Uri.parse('https://example.test'));
      client.close();
      return logs;
    }

    final a = await compose(['retry', 'breaker', 'logging']);
    final b = await compose(['logging', 'breaker', 'retry']);
    final c = await compose(['logging', 'retry', 'breaker']);

    // A duracao varia entre execucoes, entao a comparacao e sobre os
    // status, que e o que o contrato determina.
    List<int> statuses(List<String> logs) => logs
        .map((line) => int.parse(line.split(' -> ').last.split(' ').first))
        .toList();

    expect(statuses(a), [
      503,
      200,
    ], reason: 'o logging dentro do retry registra cada tentativa');
    expect(statuses(b), statuses(a), reason: 'ordem invertida: mesma cadeia');
    expect(statuses(c), statuses(a), reason: 'qualquer ordem: mesma cadeia');
  });

  test('auth decorator injects a Bearer token per request', () async {
    final seen = <String?>[];
    final client = AuthClient(
      MockClient((request) async {
        seen.add(request.headers['Authorization']);
        return http.Response('ok', 200);
      }),
      tokenProvider: () async => 'abc123',
    );

    await client.get(Uri.parse('https://example.test/items'));

    expect(seen.single, 'Bearer abc123');
    client.close();
  });

  test('auth decorator skips the header when no token is available', () async {
    final seen = <String?>[];
    final client = AuthClient(
      MockClient((request) async {
        seen.add(request.headers['Authorization']);
        return http.Response('ok', 200);
      }),
      tokenProvider: () async => null,
    );

    await client.get(Uri.parse('https://example.test/items'));

    expect(seen.single, isNull);
    client.close();
  });

  test(
    'auth decorator overrides a stale header and honors custom scheme',
    () async {
      final seen = <Map<String, String>>[];
      final client = AuthClient(
        MockClient((request) async {
          seen.add(Map.of(request.headers));
          return http.Response('ok', 200);
        }),
        tokenProvider: () async => 'rawtoken',
        headerName: 'X-Api-Key',
        scheme: '',
      );

      final request = http.Request('GET', Uri.parse('https://example.test'))
        ..headers['X-Api-Key'] = 'stale';
      await client.send(request);

      expect(seen.single['X-Api-Key'], 'rawtoken');
      client.close();
    },
  );

  test('auth decorator refreshes the token on every request', () async {
    var issued = 0;
    final seen = <String?>[];
    final client = AuthClient(
      MockClient((request) async {
        seen.add(request.headers['Authorization']);
        return http.Response('ok', 200);
      }),
      tokenProvider: () async => 'tok${++issued}',
    );

    await client.get(Uri.parse('https://example.test/a'));
    await client.get(Uri.parse('https://example.test/b'));

    expect(seen, ['Bearer tok1', 'Bearer tok2']);
    client.close();
  });

  test(
    'auth decorator logs out when the provider returns an empty token',
    () async {
      final seen = <String?>[];
      final client = AuthClient(
        MockClient((request) async {
          seen.add(request.headers['Authorization']);
          return http.Response('ok', 200);
        }),
        tokenProvider: () async => '',
      );

      await client.get(Uri.parse('https://example.test'));

      expect(seen.single, isNull);
      client.close();
    },
  );

  test('client stack composes auth with logging', () async {
    final seen = <String?>[];
    final logs = <String>[];
    final client =
        ClientStack.start(
              MockClient((request) async {
                seen.add(request.headers['Authorization']);
                return http.Response('ok', 200);
              }),
            )
            .authorized(tokenProvider: () async => 'stacktoken')
            .logging(logger: logs.add)
            .build();

    await client.get(Uri.parse('https://example.test'));

    expect(seen.single, 'Bearer stacktoken');
    expect(logs, hasLength(1));
    client.close();
  });
}

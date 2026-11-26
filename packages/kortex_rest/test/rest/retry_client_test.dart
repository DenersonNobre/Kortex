import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kortex_rest/rest/rest.dart';

void main() {
  group('RetryClient', () {
    test('does not retry a successful response', () async {
      var calls = 0;
      final client = RetryClient(
        MockClient((request) async {
          calls++;
          return http.Response('ok', 200);
        }),
        initialDelay: Duration.zero,
      );

      final response = await client.get(Uri.parse('https://example.test'));

      expect(response.statusCode, 200);
      expect(calls, 1);
      client.close();
    });

    test('retries server errors up to maxAttempts', () async {
      var calls = 0;
      final client = RetryClient(
        MockClient((request) async {
          calls++;
          return http.Response('unavailable', 503);
        }),
        maxAttempts: 3,
        initialDelay: Duration.zero,
      );

      final response = await client.get(Uri.parse('https://example.test'));

      expect(response.statusCode, 503);
      expect(calls, 3);
      client.close();
    });

    test('does not retry client errors by default', () async {
      var calls = 0;
      final client = RetryClient(
        MockClient((request) async {
          calls++;
          return http.Response('not found', 404);
        }),
        initialDelay: Duration.zero,
      );

      final response = await client.get(Uri.parse('https://example.test'));

      expect(response.statusCode, 404);
      expect(calls, 1);
      client.close();
    });

    test(
      'does not retry an open circuit: the failure is definitive, not transient',
      () async {
        var calls = 0;
        // maxAttempts: 1 isola o retry: a unica tentativa e a que pega o
        // circuito ja aberto. Sem isso o proprio retry abriria o circuito
        // dentro da mesma chamada e o teste mediria outra coisa.
        final breaker = CircuitBreakerClient(
          MockClient((request) async {
            calls++;
            return http.Response('unavailable', 500);
          }),
          failureThreshold: 1,
        );
        // Abre o circuito com uma chamada direta, fora do retry.
        await breaker.get(Uri.parse('https://example.test'));
        expect(breaker.isOpen, isTrue);
        final callsBeforeOpen = calls;

        final client = RetryClient(
          breaker,
          maxAttempts: 3,
          initialDelay: const Duration(milliseconds: 50),
        );
        final stopwatch = Stopwatch()..start();
        await expectLater(
          client.get(Uri.parse('https://example.test')),
          throwsA(isA<CircuitOpenException>()),
        );
        stopwatch.stop();

        // Nenhuma ida ao servidor e nenhum backoff: com o fix o erro
        // propaga na primeira tentativa; sem ele haveria 50 + 100 ms.
        expect(calls, callsBeforeOpen);
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(50),
          reason: 'o fast-fail do circuito nao pode ser consumido pelo backoff',
        );
        client.close();
      },
    );

    test(
      'retries network errors and rethrows after the final attempt',
      () async {
        var calls = 0;
        final client = RetryClient(
          MockClient((request) async {
            calls++;
            throw http.ClientException('offline');
          }),
          maxAttempts: 2,
          initialDelay: Duration.zero,
        );

        await expectLater(
          client.get(Uri.parse('https://example.test')),
          throwsA(isA<http.ClientException>()),
        );

        expect(calls, 2);
        client.close();
      },
    );
  });
}

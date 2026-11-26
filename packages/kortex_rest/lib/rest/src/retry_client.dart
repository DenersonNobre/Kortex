import 'dart:math' as math;

import 'package:http/http.dart' as http;

import 'circuit_breaker_client.dart';

/// Repete requisições HTTP em memória após erros de rede ou status configurados.
///
/// Cada tentativa cria uma nova requisição porque
/// [http.BaseRequest.finalize] só pode ser chamado uma vez. Requisições em
/// streaming não podem ser reproduzidas e são rejeitadas.
///
/// [CircuitOpenException] não é retentada: o circuito aberto já é uma falha
/// definitiva, e tratá-la como erro de transporte consome o backoff inteiro
/// antes de propagar, anulando o fast-fail do [CircuitBreakerClient].
class RetryClient extends http.BaseClient {
  RetryClient(
    this._inner, {
    this.maxAttempts = 3,
    this.initialDelay = const Duration(milliseconds: 200),
    this.backoffFactor = 2,
    this.shouldRetryStatus,
    this.shouldRetryRequest,
  }) : assert(maxAttempts >= 1),
       assert(backoffFactor >= 1);

  final http.Client _inner;
  final int maxAttempts;
  final Duration initialDelay;
  final double backoffFactor;
  final bool Function(int statusCode)? shouldRetryStatus;
  final bool Function(http.Request request)? shouldRetryRequest;

  bool _shouldRetry(int statusCode) =>
      shouldRetryStatus?.call(statusCode) ?? statusCode >= 500;

  bool _isReplayableMethod(http.Request request) =>
      shouldRetryRequest?.call(request) ??
      const {
        'GET',
        'HEAD',
        'OPTIONS',
        'PUT',
        'DELETE',
      }.contains(request.method.toUpperCase());

  http.Request _copyRequest(http.Request original) {
    return http.Request(original.method, original.url)
      ..headers.addAll(original.headers)
      ..bodyBytes = original.bodyBytes;
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request is! http.Request) {
      throw UnsupportedError(
        'RetryClient requires an in-memory http.Request that can be replayed.',
      );
    }
    if (!_isReplayableMethod(request)) {
      return _inner.send(_copyRequest(request));
    }

    var attempt = 1;
    while (true) {
      late http.StreamedResponse response;
      try {
        response = await _inner.send(_copyRequest(request));
      } on CircuitOpenException {
        // Falha definitiva, não transitória: o backoff só atrasaria a
        // propagação sem dar nova chance ao serviço.
        rethrow;
      } catch (_) {
        if (attempt >= maxAttempts) rethrow;
        await _wait(attempt);
        attempt++;
        continue;
      }

      if (!_shouldRetry(response.statusCode) || attempt >= maxAttempts) {
        return response;
      }

      await response.stream.drain<void>().onError((_, _) {});
      await _wait(attempt);
      attempt++;
    }
  }

  Future<void> _wait(int attempt) async {
    final multiplier = math.pow(backoffFactor, attempt - 1).toDouble();
    await Future<void>.delayed(initialDelay * multiplier);
  }

  @override
  void close() => _inner.close();
}

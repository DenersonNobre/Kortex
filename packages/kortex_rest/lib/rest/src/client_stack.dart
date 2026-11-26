import 'package:http/http.dart' as http;

import 'auth_client.dart';
import 'circuit_breaker_client.dart';
import 'logging_client.dart';
import 'null_logger.dart';
import 'retry_client.dart';

/// Composição de decorators HTTP com **ordem canônica fixa**.
///
/// A ordem de chamada dos métodos não altera o resultado: cada decorator é
/// registrado num slot e [build] monta a cadeia sempre na mesma sequência,
/// do mais externo ao mais interno:
///
/// ```text
/// CircuitBreakerClient(outer)  →  RetryClient  →  LoggingClient  →  AuthClient(inner)
/// ```
///
/// **Por que o logging fica dentro do retry**: o [RetryClient] drena e descarta
/// a resposta de cada tentativa malsucedida antes de reenviar, então um
/// decorator **externo** a ele nunca as vê. Para registrar toda tentativa — o
/// `503` que disparou o retry e o `200` final — o logging precisa observar o
/// retry por dentro. Medido com 2 tentativas: `retry > logging` = 2 linhas,
/// `logging > retry` = 1 linha.
///
/// O circuit breaker fica **por fora** de propósito: ele conta falhas por
/// requisição, e ficar entre o retry e o base faria cada tentativa interna
/// contar como falha separada, saturando o `failureThreshold` mais rápido do
/// que o chamador espera.
///
/// Ver `test/rest/middleware_test.dart` para as três ordens de registro
/// produzindo a mesma cadeia.
///
/// Os parâmetros de cada decorator são guardados na chamada e aplicados no
/// [build]; chamar o mesmo método duas vezes substitui o slot anterior.
class ClientStack {
  ClientStack(this._base);

  factory ClientStack.start(http.Client client) => ClientStack(client);

  final http.Client _base;

  RetryOptions? _retry;
  CircuitBreakerOptions? _circuitBreaker;
  HttpLogger? _logger;
  AuthOptions? _auth;

  ClientStack retrying({
    int maxAttempts = 3,
    Duration initialDelay = const Duration(milliseconds: 200),
    double backoffFactor = 2,
    bool Function(int statusCode)? shouldRetryStatus,
    bool Function(http.Request request)? shouldRetryRequest,
  }) {
    _retry = RetryOptions(
      maxAttempts: maxAttempts,
      initialDelay: initialDelay,
      backoffFactor: backoffFactor,
      shouldRetryStatus: shouldRetryStatus,
      shouldRetryRequest: shouldRetryRequest,
    );
    return this;
  }

  ClientStack withCircuitBreaker({
    int failureThreshold = 3,
    Duration resetTimeout = const Duration(seconds: 30),
  }) {
    _circuitBreaker = CircuitBreakerOptions(
      failureThreshold: failureThreshold,
      resetTimeout: resetTimeout,
    );
    return this;
  }

  ClientStack logging({HttpLogger? logger}) {
    _logger = logger ?? const NullLogger().call;
    return this;
  }

  ClientStack authorized({
    required TokenProvider tokenProvider,
    String headerName = 'Authorization',
    String scheme = 'Bearer',
  }) {
    _auth = AuthOptions(
      tokenProvider: tokenProvider,
      headerName: headerName,
      scheme: scheme,
    );
    return this;
  }

  /// Monta a cadeia na ordem canônica. Cada chamada produz um cliente novo a
  /// partir de [_base], então [build] pode ser repetido sem reaproveitar
  /// decorator de uma composição anterior.
  http.Client build() {
    var client = _base;

    final logger = _logger;
    if (logger != null) {
      client = LoggingClient(client, logger: logger);
    }

    final auth = _auth;
    if (auth != null) {
      client = AuthClient(
        client,
        tokenProvider: auth.tokenProvider,
        headerName: auth.headerName,
        scheme: auth.scheme,
      );
    }

    final retry = _retry;
    if (retry != null) {
      client = RetryClient(
        client,
        maxAttempts: retry.maxAttempts,
        initialDelay: retry.initialDelay,
        backoffFactor: retry.backoffFactor,
        shouldRetryStatus: retry.shouldRetryStatus,
        shouldRetryRequest: retry.shouldRetryRequest,
      );
    }

    final circuitBreaker = _circuitBreaker;
    if (circuitBreaker != null) {
      client = CircuitBreakerClient(
        client,
        failureThreshold: circuitBreaker.failureThreshold,
        resetTimeout: circuitBreaker.resetTimeout,
      );
    }

    return client;
  }
}

class RetryOptions {
  const RetryOptions({
    required this.maxAttempts,
    required this.initialDelay,
    required this.backoffFactor,
    this.shouldRetryStatus,
    this.shouldRetryRequest,
  });

  final int maxAttempts;
  final Duration initialDelay;
  final double backoffFactor;
  final bool Function(int statusCode)? shouldRetryStatus;
  final bool Function(http.Request request)? shouldRetryRequest;
}

class CircuitBreakerOptions {
  const CircuitBreakerOptions({
    required this.failureThreshold,
    required this.resetTimeout,
  });

  final int failureThreshold;
  final Duration resetTimeout;
}

class AuthOptions {
  const AuthOptions({
    required this.tokenProvider,
    required this.headerName,
    required this.scheme,
  });

  final TokenProvider tokenProvider;
  final String headerName;
  final String scheme;
}

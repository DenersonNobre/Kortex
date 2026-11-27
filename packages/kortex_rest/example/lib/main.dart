import 'package:kortex_rest/kortex_rest.dart';

/// Exemplo didático de composição de cliente HTTP com `kortex_rest`.
void main() {
  final logger = const NullLogger();
  print('Logger pronto: ${logger.runtimeType}');
  print('Use ClientStack, RetryClient, LoggingClient e CircuitBreakerClient');
  print('para compor decorators HTTP neutros sobre sua implementação de IRestClient.');
}

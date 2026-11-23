import 'package:http/http.dart' as http;

/// Fornece o token de acesso corrente; `null` ou vazio desliga o cabeçalho
/// (requisição anônima). Pode ser assíncrono para permitir *refresh* sob
/// demanda antes de cada requisição.
typedef TokenProvider = Future<String?> Function();

/// Decorator que injeta o token de acesso em cada requisição.
///
/// O token é resolvido a cada `send` (nunca memoizado), de modo que um
/// *refresh* do provedor vale para a próxima chamada sem reconstruir o stack.
/// Sobrescreve qualquer valor pré-existente em [headerName] — este decorator
/// é a autoridade de autenticação da requisição.
class AuthClient extends http.BaseClient {
  AuthClient(
    this._inner, {
    required this.tokenProvider,
    this.headerName = 'Authorization',
    this.scheme = 'Bearer',
  });

  final http.Client _inner;
  final TokenProvider tokenProvider;
  final String headerName;

  /// Prefixo do esquema (`'Bearer'`); vazio envia o token cru.
  final String scheme;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final token = await tokenProvider();
    if (token != null && token.isNotEmpty) {
      request.headers[headerName] = scheme.isEmpty ? token : '$scheme $token';
    }
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}

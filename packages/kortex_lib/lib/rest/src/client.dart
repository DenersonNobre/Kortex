import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class RestConfig {
  const RestConfig({this.baseUrl = '', this.timeout});

  final String baseUrl;

  /// Optional per-request timeout. When set, slow responses are aborted
  /// and mapped to a [RestResponse] with a [TimeoutException] in [RestResponse.error].
  final Duration? timeout;
}

class RestResponse {
  const RestResponse({
    this.statusCode,
    this.body,
    this.statusText = '',
    this.error,
  });

  final int? statusCode;
  final Object? body;
  final String statusText;

  /// Original transport exception (timeout, socket, DNS…), preserved
  /// for typed handling. Null on successful HTTP round-trips.
  final Object? error;

  bool get hasError => statusCode == null || statusCode! >= 400;
}

class RestClient {
  RestClient(
    this.config, {
    http.Client? httpClient,
    Map<String, String>? headers,
  }) : _client = httpClient ?? http.Client(),
       headers = {
         'Accept': 'application/json',
         'Content-Type': 'application/json',
         ...?headers,
       };

  final RestConfig config;
  final http.Client _client;
  final Map<String, String> headers;

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final base = config.baseUrl.endsWith('/')
        ? config.baseUrl.substring(0, config.baseUrl.length - 1)
        : config.baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$base$normalizedPath');
    if (query == null || query.isEmpty) return uri;

    final queryParameters = <String, String>{
      ...uri.queryParameters,
      for (final entry in query.entries) entry.key: '${entry.value}',
    };
    return uri.replace(queryParameters: queryParameters);
  }

  Object? _decode(String body) {
    if (body.isEmpty) return null;
    try {
      return jsonDecode(body);
    } on FormatException {
      return body;
    }
  }

  /// Decodifica o corpo respeitando o `charset` do Content-Type.
  /// Ausente ou desconhecido: fallback para UTF-8.
  String _decodeBody(http.Response response) {
    final contentType = response.headers['content-type'] ?? '';
    final match = RegExp(
      r'charset=([^;\s]+)',
      caseSensitive: false,
    ).firstMatch(contentType);
    final name = match?.group(1)?.replaceAll('"', '');
    final encoding = name == null ? null : Encoding.getByName(name);
    return (encoding ?? utf8).decode(response.bodyBytes);
  }

  RestResponse _fromHttp(http.Response response) {
    return RestResponse(
      statusCode: response.statusCode,
      body: _decode(_decodeBody(response)),
      statusText: response.reasonPhrase ?? '',
    );
  }

  Future<RestResponse> _send(Future<http.Response> Function() send) async {
    try {
      var future = send();
      final timeout = config.timeout;
      if (timeout != null) {
        future = future.timeout(timeout);
      }
      return _fromHttp(await future);
    } catch (error) {
      return RestResponse(statusText: error.toString(), error: error);
    }
  }

  Future<RestResponse> get(String path, {Map<String, dynamic>? query}) {
    return _send(() => _client.get(_uri(path, query), headers: headers));
  }

  Future<RestResponse> post(String path, Object? body) {
    return _send(
      () => _client.post(_uri(path), headers: headers, body: jsonEncode(body)),
    );
  }

  Future<RestResponse> put(String path, Object? body) {
    return _send(
      () => _client.put(_uri(path), headers: headers, body: jsonEncode(body)),
    );
  }

  Future<RestResponse> patch(String path, Object? body) {
    return _send(
      () => _client.patch(_uri(path), headers: headers, body: jsonEncode(body)),
    );
  }

  Future<RestResponse> delete(String path) {
    return _send(() => _client.delete(_uri(path), headers: headers));
  }

  void close() => _client.close();
}

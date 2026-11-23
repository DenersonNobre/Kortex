import 'package:http/http.dart' as http;

import 'client_decorator_base.dart';
import 'null_logger.dart';

class LoggingClient extends ClientDecoratorBase {
  LoggingClient(super.inner, {HttpLogger? logger})
    : _logger = logger ?? const NullLogger().call;

  final HttpLogger _logger;
  final Map<http.BaseRequest, DateTime> _startedAt = {};

  @override
  void onBefore(http.BaseRequest request) {
    _startedAt[request] = DateTime.now();
  }

  @override
  void onSuccess(http.BaseRequest request, http.StreamedResponse response) {
    _logger(
      '${request.method} ${_safeUrl(request.url)} -> '
      '${response.statusCode} (${_durationMs(request)}ms)',
    );
  }

  @override
  void onError(http.BaseRequest request, Object error) {
    _logger(
      '${request.method} ${_safeUrl(request.url)} -> '
      'ERROR (${_durationMs(request)}ms)',
    );
  }

  String _safeUrl(Uri uri) => Uri(
    scheme: uri.scheme,
    host: uri.host,
    port: uri.hasPort ? uri.port : null,
    path: uri.path,
  ).toString();

  int _durationMs(http.BaseRequest request) {
    final startedAt = _startedAt.remove(request);
    return startedAt == null
        ? 0
        : DateTime.now().difference(startedAt).inMilliseconds;
  }
}

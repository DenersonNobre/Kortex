import 'package:http/http.dart' as http;

abstract class ClientDecoratorBase extends http.BaseClient {
  ClientDecoratorBase(this.inner);

  final http.Client inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    onBefore(request);
    try {
      final response = await inner.send(request);
      onSuccess(request, response);
      return response;
    } catch (error) {
      onError(request, error);
      rethrow;
    }
  }

  void onBefore(http.BaseRequest request) {}

  void onSuccess(http.BaseRequest request, http.StreamedResponse response) {}

  void onError(http.BaseRequest request, Object error) {}

  @override
  void close() => inner.close();
}

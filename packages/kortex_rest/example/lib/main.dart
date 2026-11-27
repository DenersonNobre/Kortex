import 'package:http/http.dart' as http;
import 'package:kortex_rest/kortex_rest.dart';

/// Exemplo didático de composição de decorators HTTP com `ClientStack`.
Future<void> main() async {
  final baseClient = _FakeHttpClient();

  final client = ClientStack.start(baseClient)
      .retrying(maxAttempts: 2)
      .build();

  final response = await client.get(Uri.parse('https://api.exemplo.com/ping'));
  print('Status: ${response.statusCode} | Body: ${response.body}');
  client.close();
}

class _FakeHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      Stream.value('{"ok":true}'.codeUnits),
      200,
    );
  }
}

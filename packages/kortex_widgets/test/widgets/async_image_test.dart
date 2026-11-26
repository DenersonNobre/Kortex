import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex_widgets/kortex_widgets.dart';

/// GIF 1x1 transparente — payload válido para decodificação pelo codec.
final Uint8List _gif = base64Decode(
  'R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7',
);

void main() {
  testWidgets('AsyncImage mostra o ícone padrão de erro quando a rede falha', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AsyncImage(url: 'http://x/img.png')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    expect(find.byType(TextButton), findsNothing);
  });

  testWidgets('AsyncImage exibe e aciona o botão de repetir no erro', (
    tester,
  ) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AsyncImage(
            url: 'http://x/img.png',
            onRetry: () => retried = true,
            retryLabel: 'Tentar de novo',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final button = find.widgetWithText(TextButton, 'Tentar de novo');
    expect(button, findsOneWidget);
    await tester.tap(button);
    expect(retried, isTrue);
  });

  testWidgets('AsyncImage sem retryLabel não mostra botão mesmo com onRetry', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AsyncImage(url: 'http://x/img.png', onRetry: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    expect(find.byType(TextButton), findsNothing);
  });

  testWidgets('AsyncImage usa o errorBuilder do chamador quando informado', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AsyncImage(url: 'http://x/img.png', errorBuilder: _customError),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Falha customizada'), findsOneWidget);
    expect(find.byIcon(Icons.broken_image_outlined), findsNothing);
  });

  testWidgets('AsyncImage exibe progresso durante o carregamento e conclui', (
    tester,
  ) async {
    debugNetworkImageHttpClientProvider = () =>
        _FakeHttpClient(contentLength: _gif.length, chunked: true);
    addTearDown(() => debugNetworkImageHttpClientProvider = null);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AsyncImage(url: 'http://x/progress.png')),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await _finishRealAsync(tester);

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byIcon(Icons.broken_image_outlined), findsNothing);
  });

  testWidgets('AsyncImage usa o loadingBuilder do chamador quando informado', (
    tester,
  ) async {
    var loadingCalled = false;
    debugNetworkImageHttpClientProvider = () =>
        _FakeHttpClient(contentLength: _gif.length, chunked: true);
    addTearDown(() => debugNetworkImageHttpClientProvider = null);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AsyncImage(
            url: 'http://x/custom-loading.png',
            loadingBuilder: (context) {
              loadingCalled = true;
              return const Text('Carregando');
            },
          ),
        ),
      ),
    );
    await tester.pump();

    expect(loadingCalled, isTrue);

    await _finishRealAsync(tester);

    expect(find.byIcon(Icons.broken_image_outlined), findsNothing);
  });

  testWidgets('AsyncImage mostra indicador indeterminado sem total de bytes', (
    tester,
  ) async {
    debugNetworkImageHttpClientProvider = () =>
        _FakeHttpClient(contentLength: -1, chunked: false);
    addTearDown(() => debugNetworkImageHttpClientProvider = null);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AsyncImage(url: 'http://x/no-length.png')),
      ),
    );
    await tester.pump();
    await tester.pump();

    final progress = find.byType(CircularProgressIndicator);
    expect(progress, findsOneWidget);
    expect(tester.widget<CircularProgressIndicator>(progress).value, isNull);

    await _finishRealAsync(tester);

    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}

/// O decode do codec roda em async real (engine) e não avança sob FakeAsync:
/// `runAsync` libera o relógio real até a imagem estar pronta.
Future<void> _finishRealAsync(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pumpAndSettle();
  // O _verifyInvariants do binding roda ANTES do addTearDown: o provider
  // precisa voltar a null dentro do corpo do teste.
  debugNetworkImageHttpClientProvider = null;
}

Widget _customError(BuildContext context, Object error, StackTrace? stack) =>
    const Text('Falha customizada');

class _FakeHttpClient implements HttpClient {
  _FakeHttpClient({required this.contentLength, required this.chunked});

  final int contentLength;
  final bool chunked;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async =>
      _FakeRequest(contentLength: contentLength, chunked: chunked);

  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('HttpClient.${invocation.memberName}');
}

class _FakeRequest implements HttpClientRequest {
  _FakeRequest({required this.contentLength, required this.chunked});

  @override
  final int contentLength;
  final bool chunked;

  @override
  final HttpHeaders headers = _FakeHeaders();

  @override
  Future<HttpClientResponse> close() async {
    final stream = chunked
        ? Stream<Uint8List>.fromIterable([
            _gif.sublist(0, _gif.length ~/ 2),
            _gif.sublist(_gif.length ~/ 2),
          ])
        : Stream<Uint8List>.fromIterable([_gif]);
    return _FakeResponse(stream, contentLength: contentLength);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('HttpClientRequest.${invocation.memberName}');
}

class _FakeHeaders implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('HttpHeaders.${invocation.memberName}');
}

class _FakeResponse extends StreamView<List<int>>
    implements HttpClientResponse {
  _FakeResponse(super.stream, {required this.contentLength});

  @override
  final int contentLength;

  @override
  final int statusCode = HttpStatus.ok;

  @override
  final HttpHeaders headers = _FakeHeaders();

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => false;

  @override
  String get reasonPhrase => 'OK';

  @override
  List<RedirectInfo> get redirects => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('HttpClientResponse.${invocation.memberName}');
}

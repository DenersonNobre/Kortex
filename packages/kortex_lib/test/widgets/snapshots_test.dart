import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex_lib/widgets/widgets.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('SnapshotBuild mostra indicador padrao sem loadingBuilder', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        SnapshotBuild<String>(
          snapshot: const AsyncSnapshot<String>.waiting(),
          builder: (context, snapshot) => Text(snapshot.data!),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('SnapshotBuild mostra icone de erro padrao sem errorBuilder', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        SnapshotBuild<String>(
          snapshot: const AsyncSnapshot<String>.withError(
            ConnectionState.done,
            'falha',
          ),
          builder: (context, snapshot) => Text(snapshot.data!),
        ),
      ),
    );

    final icon = tester.widget<Icon>(find.byIcon(Icons.error_outline));
    final scheme = Theme.of(tester.element(find.byIcon(Icons.error_outline)));
    expect(icon.color, scheme.colorScheme.error);
  });

  testWidgets('SnapshotBuild sem emptyBuilder devolve caixa vazia', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        SnapshotBuild<String?>(
          snapshot: const AsyncSnapshot<String?>.withData(
            ConnectionState.done,
            null,
          ),
          builder: (context, snapshot) => Text(snapshot.data!),
        ),
      ),
    );

    expect(find.byType(SizedBox), findsWidgets);
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('FutureSnapshot passa por loading, dado e erro', (tester) async {
    final completer = Completer<String>();
    Future<String> future() => completer.future;

    await tester.pumpWidget(
      wrap(
        FutureSnapshot<String>(
          future: future(),
          builder: (context, snapshot) => Text(snapshot.data!),
          loadingBuilder: (_) => const Text('Carregando'),
          errorBuilder: (_, snapshot) => Text('Erro: ${snapshot.error}'),
        ),
      ),
    );
    expect(find.text('Carregando'), findsOneWidget);

    completer.complete('Conteudo');
    await tester.pumpAndSettle();
    expect(find.text('Conteudo'), findsOneWidget);

    final failing = Completer<String>();
    await tester.pumpWidget(
      wrap(
        FutureSnapshot<String>(
          future: failing.future,
          builder: (context, snapshot) => Text(snapshot.data!),
          loadingBuilder: (_) => const Text('Carregando'),
          errorBuilder: (_, snapshot) => Text('Erro: ${snapshot.error}'),
        ),
      ),
    );
    failing.completeError('boom');
    await tester.pumpAndSettle();
    expect(find.text('Erro: boom'), findsOneWidget);
  });

  testWidgets('StreamSnapshot entrega o dado emitido e propaga erro', (
    tester,
  ) async {
    final controller = StreamController<String>();
    addTearDown(controller.close);

    await tester.pumpWidget(
      wrap(
        StreamSnapshot<String>(
          stream: controller.stream,
          builder: (context, snapshot) => Text(snapshot.data!),
          loadingBuilder: (_) => const Text('Aguardando'),
          errorBuilder: (_, snapshot) => Text('Erro: ${snapshot.error}'),
        ),
      ),
    );
    expect(find.text('Aguardando'), findsOneWidget);

    controller.add('Valor');
    await tester.pumpAndSettle();
    expect(find.text('Valor'), findsOneWidget);

    final failing = StreamController<String>();
    addTearDown(failing.close);
    await tester.pumpWidget(
      wrap(
        StreamSnapshot<String>(
          stream: failing.stream,
          builder: (context, snapshot) => Text(snapshot.data!),
          loadingBuilder: (_) => const Text('Aguardando'),
          errorBuilder: (_, snapshot) => Text('Erro: ${snapshot.error}'),
        ),
      ),
    );
    failing.addError('stream falhou');
    await tester.pumpAndSettle();
    expect(find.text('Erro: stream falhou'), findsOneWidget);
  });
}

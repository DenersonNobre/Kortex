import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex/kortex.dart';
import 'package:kortex_widgets/src/widgets/async_page.dart';

/// Fake loader with a gate and programmable failures (no real network).
class _FakeSource {
  _FakeSource();

  Completer<String>? gate;
  Object? failure;
  int calls = 0;

  Future<String> load() {
    calls++;
    final gate = this.gate;
    if (gate != null) return gate.future;
    final failure = this.failure;
    if (failure != null) return Future<String>.error(failure);
    return Future<String>.value('hello');
  }
}

/// Resources owned by the running test (house leak gate, `UC-12.00` pattern).
final List<KortexResource<String>> _openResources = [];

KortexResource<String> _track(KortexResource<String> resource) {
  _openResources.add(resource);
  return resource;
}

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

Widget _page(
  KortexResource<String> resource, {
  Widget Function(BuildContext, String)? contentBuilder,
}) => AsyncPage<String>(
  resource: resource,
  contentBuilder:
      contentBuilder ??
      (context, value) =>
          Text(value, key: const ValueKey<String>('async_page_content')),
);

void main() {
  tearDown(() {
    final forgotten = <KortexResource<String>>[];
    final alive = <KortexResource<String>>[];
    for (final resource in _openResources) {
      if (!resource.isDisposed) forgotten.add(resource);
      if (!resource.isDisposed) resource.dispose();
      if (!resource.isDisposed) alive.add(resource);
    }
    _openResources.clear();
    expect(
      forgotten,
      isEmpty,
      reason: 'Resources esquecidos sem dispose: $forgotten',
    );
    expect(alive, isEmpty, reason: 'Resources nao descartados: $alive');
  });

  group('UC-12.02 AsyncPage', () {
    testWidgets('loading resolve em content sem flash de empty', (tester) async {
      final source = _FakeSource()..gate = Completer<String>();
      final resource = _track(
        KortexResource<String>(source.load, immediate: false),
      );

      await tester.pumpWidget(_wrap(_page(resource)));
      final pending = resource.refresh();
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('hello'), findsNothing);
      // Sem flash de empty: EmptyState nunca aparece no caminho loading->data.
      expect(find.text('No items'), findsNothing);

      source.gate!.complete('hello');
      await pending;
      await tester.pumpAndSettle();

      expect(find.text('hello'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('No items'), findsNothing);

      await tester.pumpWidget(_wrap(const SizedBox()));
      expect(resource.isDisposed, isFalse);

      resource.dispose();
      expect(resource.isDisposed, isTrue);
    });

    testWidgets('error com retry recarrega e exibe loading', (tester) async {
      final source = _FakeSource()..failure = 'page boom';
      final resource = _track(
        KortexResource<String>(source.load, immediate: false),
      );

      await tester.pumpWidget(_wrap(_page(resource)));
      await resource.refresh();
      await tester.pumpAndSettle();

      expect(find.text('page boom'), findsOneWidget);
      expect(find.text('hello'), findsNothing);

      source.failure = null;
      source.gate = Completer<String>();
      final pending = resource.refresh();
      await tester.pump();

      // Retry exibe loading de novo.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('page boom'), findsNothing);

      source.gate!.complete('hello');
      await pending;
      await tester.pumpAndSettle();

      expect(find.text('hello'), findsOneWidget);
      expect(source.calls, 2);

      await tester.pumpWidget(_wrap(const SizedBox()));
      expect(resource.isDisposed, isFalse);

      resource.dispose();
      expect(resource.isDisposed, isTrue);
    });

    testWidgets('error expoe botao retry com mensagem acessivel', (
      tester,
    ) async {
      final source = _FakeSource()..failure = 'page boom';
      final resource = _track(
        KortexResource<String>(source.load, immediate: false),
      );

      await tester.pumpWidget(
        _wrap(
          AsyncPage<String>(
            resource: resource,
            contentBuilder: (context, value) => Text(value),
            errorMessage: 'Falha ao carregar',
          ),
        ),
      );
      await resource.refresh();
      await tester.pumpAndSettle();

      // Mensagem acessivel via Semantics + tooltip do retry.
      expect(find.text('Falha ao carregar'), findsOneWidget);
      expect(find.byTooltip('Retry'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Tap no retry recarrega (prova que o botao esta vivo).
      source.failure = null;
      await tester.tap(find.byTooltip('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('hello'), findsOneWidget);
      expect(source.calls, 2);

      await tester.pumpWidget(_wrap(const SizedBox()));
      expect(resource.isDisposed, isFalse);

      resource.dispose();
      expect(resource.isDisposed, isTrue);
    });

    testWidgets('descarte do resource em voo descarta o tardio sem excecao', (
      tester,
    ) async {
      final source = _FakeSource()..gate = Completer<String>();
      final resource = _track(
        KortexResource<String>(source.load, immediate: false),
      );

      await tester.pumpWidget(_wrap(_page(resource)));
      final pending = resource.refresh();
      await tester.pump();

      resource.dispose();
      expect(resource.isDisposed, isTrue);

      await tester.pumpWidget(_wrap(const SizedBox()));
      source.gate!.complete('late');
      await pending;
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('late'), findsNothing);
    });

    testWidgets('unmount nao dispoe o resource (dono e o caller)', (
      tester,
    ) async {
      final source = _FakeSource();
      final resource = _track(
        KortexResource<String>(source.load, immediate: false),
      );

      await tester.pumpWidget(_wrap(_page(resource)));
      await resource.refresh();
      await tester.pumpAndSettle();

      expect(find.text('hello'), findsOneWidget);

      await tester.pumpWidget(_wrap(const SizedBox()));
      expect(resource.isDisposed, isFalse);

      resource.dispose();
      expect(resource.isDisposed, isTrue);
    });
  });
}

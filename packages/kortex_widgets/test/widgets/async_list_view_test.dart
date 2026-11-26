import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex_widgets/src/widgets/async_list_view.dart';

/// Injected paged source with per-page gates and failures (no real network).
class _FakePages {
  _FakePages(this.pages);

  final Map<int, List<String>> pages;
  final Map<int, int> calls = {};
  final Map<int, Completer<List<String>>> gates = {};
  int? errorPage;
  Object? pageError;

  Future<List<String>> load(int page) {
    calls[page] = (calls[page] ?? 0) + 1;
    final gate = gates[page];
    if (gate != null) return gate.future;
    final failure = errorPage == page ? pageError : null;
    if (failure != null) return Future<List<String>>.error(failure);
    return Future<List<String>>.value(List<String>.of(pages[page] ?? []));
  }
}

/// Controllers owned by the running test (house leak gate, `UC-12.00` pattern).
final List<AsyncListController<String>> _openControllers = [];

AsyncListController<String> _track(AsyncListController<String> controller) {
  _openControllers.add(controller);
  return controller;
}

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

Widget _rows(AsyncListController<String> controller) => AsyncListView<String>(
  controller: controller,
  itemExtent: 72,
  skeletonCount: 3,
  itemBuilder: (context, item, _) => Text(item, key: ValueKey('row_$item')),
);

void main() {
  tearDown(() {
    final forgotten = <AsyncListController<String>>[];
    final alive = <AsyncListController<String>>[];
    for (final controller in _openControllers) {
      if (!controller.isDisposed) forgotten.add(controller);
      if (!controller.isDisposed) controller.dispose();
      if (!controller.isDisposed) alive.add(controller);
    }
    _openControllers.clear();
    expect(
      forgotten,
      isEmpty,
      reason: 'Controllers esquecidos sem dispose: $forgotten',
    );
    expect(alive, isEmpty, reason: 'Controllers nao descartados: $alive');
  });

  group('UC-12.01 AsyncListView', () {
    testWidgets('scroll ate o fim anexa a proxima pagina sem duplicar', (
      tester,
    ) async {
      final source = _FakePages({
        0: [for (var i = 0; i < 10; i++) 'item$i'],
        1: ['item9', 'item10'],
      });
      final controller = _track(
        AsyncListController<String>(loadPage: source.load, immediate: false),
      );

      await tester.pumpWidget(_wrap(_rows(controller)));
      await controller.refresh();
      await tester.pumpAndSettle();

      expect(find.text('item0'), findsOneWidget);
      expect(controller.items.value, hasLength(10));

      await tester.drag(
        find.byKey(const ValueKey<String>('async_list_data')),
        const Offset(0, -600),
      );
      await tester.pumpAndSettle();

      expect(source.calls[1], 1);
      expect(controller.items.value, hasLength(11));

      await tester.drag(
        find.byKey(const ValueKey<String>('async_list_data')),
        const Offset(0, -600),
      );
      await tester.pumpAndSettle();

      expect(find.text('item9'), findsOneWidget);
      expect(find.text('item10'), findsOneWidget);

      await tester.pumpWidget(_wrap(const SizedBox()));
      expect(controller.isDisposed, isFalse);

      controller.dispose();
      expect(controller.isDisposed, isTrue);
    });

    testWidgets('loadMore concorrente dispara uma unica carga da cauda', (
      tester,
    ) async {
      final source = _FakePages({
        0: ['a', 'b'],
        1: ['c'],
      });
      source.gates[1] = Completer<List<String>>();
      final controller = _track(
        AsyncListController<String>(loadPage: source.load, immediate: false),
      );

      await tester.pumpWidget(_wrap(_rows(controller)));
      await controller.refresh();
      await tester.pump();

      final first = controller.loadMore();
      final second = controller.loadMore();
      source.gates[1]!.complete(['c']);
      await first;
      await second;
      await tester.pumpAndSettle();

      expect(source.calls[1], 1);
      expect(controller.items.value, ['a', 'b', 'c']);
      expect(find.text('c'), findsOneWidget);

      await tester.pumpWidget(_wrap(const SizedBox()));
      expect(controller.isDisposed, isFalse);

      controller.dispose();
      expect(controller.isDisposed, isTrue);
    });

    testWidgets('refresh durante loadMore em voo vence sem itens fantasmas', (
      tester,
    ) async {
      final source = _FakePages({
        0: ['a', 'b'],
      });
      source.gates[1] = Completer<List<String>>();
      final controller = _track(
        AsyncListController<String>(loadPage: source.load, immediate: false),
      );

      await tester.pumpWidget(_wrap(_rows(controller)));
      await controller.refresh();
      await tester.pump();

      final pending = controller.loadMore();
      source.pages[0] = ['x', 'y'];
      await controller.refresh();
      await tester.pump();
      source.gates[1]!.complete(['ghost']);
      await pending;
      await tester.pumpAndSettle();

      expect(controller.items.value, ['x', 'y']);
      expect(controller.isLoadingMore.value, isFalse);
      expect(find.text('x'), findsOneWidget);
      expect(find.text('y'), findsOneWidget);
      expect(find.text('ghost'), findsNothing);
      expect(find.text('a'), findsNothing);

      await tester.pumpWidget(_wrap(const SizedBox()));
      expect(controller.isDisposed, isFalse);

      controller.dispose();
      expect(controller.isDisposed, isTrue);
    });

    testWidgets('erro no loadMore preserva a lista e retry recarrega a cauda', (
      tester,
    ) async {
      final source = _FakePages({
        0: ['a', 'b'],
        1: ['c'],
      });
      final controller = _track(
        AsyncListController<String>(loadPage: source.load, immediate: false),
      );

      await tester.pumpWidget(_wrap(_rows(controller)));
      await controller.refresh();
      await tester.pumpAndSettle();

      source.errorPage = 1;
      source.pageError = 'tail boom';
      await controller.loadMore();
      await tester.pumpAndSettle();

      expect(controller.items.value, ['a', 'b']);
      expect(find.text('a'), findsOneWidget);
      expect(find.text('tail boom'), findsOneWidget);
      expect(source.calls[0], 1);

      source.errorPage = null;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(source.calls[0], 1);
      expect(source.calls[1], 2);
      expect(controller.items.value, ['a', 'b', 'c']);
      expect(find.text('c'), findsOneWidget);
      expect(find.text('tail boom'), findsNothing);

      await tester.pumpWidget(_wrap(const SizedBox()));
      expect(controller.isDisposed, isFalse);

      controller.dispose();
      expect(controller.isDisposed, isTrue);
    });

    testWidgets('skeleton inicial tem altura fixa e troca sem layout shift', (
      tester,
    ) async {
      final source = _FakePages({
        0: ['a', 'b', 'c'],
      });
      source.gates[0] = Completer<List<String>>();
      final controller = _track(
        AsyncListController<String>(loadPage: source.load, immediate: false),
      );

      await tester.pumpWidget(_wrap(_rows(controller)));
      final pending = controller.refresh();
      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('async_list_skeleton')),
        findsOneWidget,
      );
      final skeletonRect = tester.getRect(
        find.byKey(const ValueKey<String>('async_list_skeleton_0')),
      );
      expect(skeletonRect.height, 72);

      source.gates[0]!.complete(['a', 'b', 'c']);
      await pending;
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('async_list_data')),
        findsOneWidget,
      );
      final rowRect = tester.getRect(find.byKey(const ValueKey('row_a')));
      expect(rowRect.height, 72);
      expect((rowRect.height - skeletonRect.height).abs(), lessThan(0.5));

      await tester.pumpWidget(_wrap(const SizedBox()));
      expect(controller.isDisposed, isFalse);

      controller.dispose();
      expect(controller.isDisposed, isTrue);
    });

    testWidgets('primeira pagina vazia exibe EmptyState e nao busca cauda', (
      tester,
    ) async {
      final source = _FakePages({0: const []});
      final controller = _track(
        AsyncListController<String>(loadPage: source.load, immediate: false),
      );

      await tester.pumpWidget(_wrap(_rows(controller)));
      await controller.refresh();
      await tester.pumpAndSettle();

      expect(find.text('No items'), findsOneWidget);
      expect(controller.hasMore.value, isFalse);

      await controller.loadMore();
      await tester.pump();
      expect(source.calls.containsKey(1), isFalse);

      await tester.pumpWidget(_wrap(const SizedBox()));
      expect(controller.isDisposed, isFalse);

      controller.dispose();
      expect(controller.isDisposed, isTrue);
    });

    testWidgets('erro na primeira pagina exibe retry e refresh recupera', (
      tester,
    ) async {
      final source = _FakePages({
        0: ['a'],
      });
      source.errorPage = 0;
      source.pageError = 'head boom';
      final controller = _track(
        AsyncListController<String>(loadPage: source.load, immediate: false),
      );

      await tester.pumpWidget(_wrap(_rows(controller)));
      await controller.refresh();
      await tester.pumpAndSettle();

      expect(find.text('head boom'), findsOneWidget);
      expect(controller.items.value, isEmpty);

      source.errorPage = null;
      await tester.tap(find.byTooltip('Retry'));
      await tester.pumpAndSettle();

      expect(source.calls[0], 2);
      expect(find.text('a'), findsOneWidget);

      await tester.pumpWidget(_wrap(const SizedBox()));
      expect(controller.isDisposed, isFalse);

      controller.dispose();
      expect(controller.isDisposed, isTrue);
    });

    testWidgets('descarte em voo descarta o tardio sem excecao em zona', (
      tester,
    ) async {
      final source = _FakePages({
        0: ['a'],
      });
      source.gates[0] = Completer<List<String>>();
      final controller = _track(
        AsyncListController<String>(loadPage: source.load, immediate: false),
      );

      await tester.pumpWidget(_wrap(_rows(controller)));
      final pending = controller.refresh();
      await tester.pump();

      controller.dispose();
      expect(controller.isDisposed, isTrue);

      await tester.pumpWidget(_wrap(const SizedBox()));
      source.gates[0]!.complete(['late']);
      await pending;
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('late'), findsNothing);
    });
  });
}

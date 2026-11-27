import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex_widgets/src/widgets/searchable_select.dart';

/// Async source with one gate per query (no real network, no real delay).
class _FakeOptions {
  _FakeOptions();

  final Map<String, Completer<List<String>>> gates = {};
  final List<String> queries = [];

  Future<List<String>> load(String query) {
    queries.add(query);
    final gate = gates[query];
    if (gate != null) return gate.future;
    return Future<List<String>>.value(<String>['$query-1', '$query-2']);
  }
}

/// Controllers owned by the running test (house leak gate, `UC-12.00` pattern).
final List<SearchableSelectController<String>> _openControllers = [];

SearchableSelectController<String> _track(
  SearchableSelectController<String> controller,
) {
  _openControllers.add(controller);
  return controller;
}

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

Widget _sheet(
  SearchableSelectController<String> controller, {
  void Function(List<String>)? onConfirm,
}) => SearchableSelectSheet<String>(
  controller: controller,
  optionLabel: (option) => option,
  onConfirm: onConfirm,
);

SearchableSelectController<String> _controller(
  _FakeOptions source, {
  bool multi = true,
}) => _track(
  SearchableSelectController<String>(
    optionsLoader: source.load,
    debounce: Duration.zero,
    multi: multi,
    immediate: false,
  ),
);

void main() {
  tearDown(() {
    final forgotten = <SearchableSelectController<String>>[];
    final alive = <SearchableSelectController<String>>[];
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

  group('UC-12.03 SearchableSelect', () {
    testWidgets('busca antiga cancelada: so o ultimo resultado renderiza', (
      tester,
    ) async {
      final source = _FakeOptions();
      source.gates['old'] = Completer<List<String>>();
      source.gates['new'] = Completer<List<String>>();
      final controller = _controller(source);

      await tester.pumpWidget(_wrap(_sheet(controller)));
      controller.search('old');
      await tester.pump();
      controller.search('new');
      await tester.pump();

      // A busca nova entra em loading; a antiga segue pendente sem pintar nada.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('old-1'), findsNothing);

      // Completa FORA DE ORDEM: a antiga resolve depois da nova.
      source.gates['new']!.complete(<String>['new-1', 'new-2']);
      await tester.pumpAndSettle();
      source.gates['old']!.complete(<String>['old-1', 'old-2']);
      await tester.pumpAndSettle();

      // Positivo: so o ultimo resultado renderiza.
      expect(find.text('new-1'), findsOneWidget);
      expect(find.text('new-2'), findsOneWidget);
      // Negativos: o tardio foi descartado em silencio, sem loading preso.
      expect(find.text('old-1'), findsNothing);
      expect(find.text('old-2'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.pumpWidget(_wrap(const SizedBox()));
      expect(controller.isDisposed, isFalse);

      controller.dispose();
      expect(controller.isDisposed, isTrue);
    });

    testWidgets('confirmar entrega os selecionados (multi)', (tester) async {
      final source = _FakeOptions();
      final controller = _controller(source);
      var confirmed = <String>[];
      var calls = 0;

      await tester.pumpWidget(
        _wrap(
          _sheet(
            controller,
            onConfirm: (selection) {
              calls++;
              confirmed = selection;
            },
          ),
        ),
      );
      await controller.search('ab');
      await tester.pumpAndSettle();

      expect(find.text('ab-1'), findsOneWidget);
      expect(find.text('ab-2'), findsOneWidget);

      await tester.tap(find.text('ab-1'));
      await tester.pump();
      await tester.tap(find.text('ab-2'));
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey<String>('confirm')));
      await tester.pump();

      // Positivo: os dois selecionados chegam ao callback (pronto p/ KortexField).
      expect(confirmed, <String>['ab-1', 'ab-2']);
      expect(calls, 1);
      // Negativos: nada alem do marcado foi entregue; loading nao ficou preso.
      expect(confirmed, hasLength(2));
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.pumpWidget(_wrap(const SizedBox()));
      expect(controller.isDisposed, isFalse);

      controller.dispose();
      expect(controller.isDisposed, isTrue);
    });

    testWidgets('single substitui a selecao; vazio mostra empty', (
      tester,
    ) async {
      final source = _FakeOptions();
      source.gates['q'] = Completer<List<String>>();
      final controller = _controller(source, multi: false);
      var confirmed = <String>[];

      await tester.pumpWidget(
        _wrap(_sheet(controller, onConfirm: (selection) => confirmed = selection)),
      );
      controller.search('q');
      await tester.pump();

      // Vazio em voo vira loading, nao empty prematuro.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('No options'), findsNothing);

      source.gates['q']!.complete(<String>[]);
      await tester.pumpAndSettle();

      // Positivo: fonte vazia rende o empty do sheet.
      expect(find.text('No options'), findsOneWidget);
      // Negativo: nenhuma opcao fantasma aparece no vazio.
      expect(find.text('q-1'), findsNothing);

      source.gates['q2'] = Completer<List<String>>();
      controller.search('q2');
      await tester.pump();
      source.gates['q2']!.complete(<String>['a', 'b']);
      await tester.pumpAndSettle();

      await tester.tap(find.text('a'));
      await tester.pump();
      await tester.tap(find.text('b'));
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey<String>('confirm')));
      await tester.pump();

      // Positivo: single troca, nao acumula.
      expect(confirmed, <String>['b']);
      // Negativos: o anterior saiu; confirm nao disparou sozinho antes.
      expect(confirmed, isNot(contains('a')));
      expect(controller.selected.value, hasLength(1));

      await tester.pumpWidget(_wrap(const SizedBox()));
      expect(controller.isDisposed, isFalse);

      controller.dispose();
      expect(controller.isDisposed, isTrue);
    });

    testWidgets('descarte em voo descarta o tardio sem excecao em zona', (
      tester,
    ) async {
      final source = _FakeOptions();
      source.gates['q'] = Completer<List<String>>();
      final controller = _controller(source);

      await tester.pumpWidget(_wrap(_sheet(controller)));
      controller.search('q');
      await tester.pump();

      controller.dispose();
      expect(controller.isDisposed, isTrue);

      await tester.pumpWidget(_wrap(const SizedBox()));
      source.gates['q']!.complete(<String>['late-1']);
      await tester.pumpAndSettle();

      // Positivo: nada explode; negativo duplo: tardio nao pinta, erro some.
      expect(tester.takeException(), isNull);
      expect(find.text('late-1'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('unmount nao dispoe o controller (dono e o caller)', (
      tester,
    ) async {
      final source = _FakeOptions();
      final controller = _controller(source);

      await tester.pumpWidget(_wrap(_sheet(controller)));
      await controller.search('ab');
      await tester.pumpAndSettle();

      expect(find.text('ab-1'), findsOneWidget);

      await tester.pumpWidget(_wrap(const SizedBox()));
      // Positivo: o dono segue vivo; negativo: valores nao evaporam no unmount.
      expect(controller.isDisposed, isFalse);
      expect(controller.options.peek(), <String>['ab-1', 'ab-2']);

      controller.dispose();
      expect(controller.isDisposed, isTrue);
    });
  });
}

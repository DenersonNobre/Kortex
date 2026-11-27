import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex_widgets/src/widgets/filter_panel.dart';

/// Variable-width options (the `UC-12.04` Gherkin setup: chips must not
/// reflow when the selection flips).
List<FilterOption<String>> _options() => const <FilterOption<String>>[
  FilterOption<String>(value: 'a', label: 'A'),
  FilterOption<String>(value: 'b', label: 'Medium label'),
  FilterOption<String>(value: 'c', label: 'A very long filter label here'),
];

/// Controllers owned by the running test (house leak gate, `UC-12.00` pattern).
final List<FilterPanelController<String>> _openControllers = [];

FilterPanelController<String> _track(FilterPanelController<String> controller) {
  _openControllers.add(controller);
  return controller;
}

FilterPanelController<String> _controller({bool multi = true}) => _track(
  FilterPanelController<String>(
    initialSelection: const <String>[],
    multi: multi,
  ),
);

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

Widget _panel(
  FilterPanelController<String> controller, {
  void Function(Set<String>)? onChanged,
}) => FilterPanel<String>(
  options: _options(),
  controller: controller,
  onSelectionChanged: onChanged,
);

/// Taps the chip showing [label] through its stable chip key (tapping the
/// raw `Text` center misses hit-test on the chip internals).
Future<void> _tapChip(WidgetTester tester, String label) {
  return tester.tap(find.byKey(ValueKey<String>('filter_$label')));
}

/// House unmount + dispose epilogue (proves caller ownership per test).
Future<void> _unmountAndDispose(
  WidgetTester tester,
  FilterPanelController<String> controller,
) async {
  await tester.pumpWidget(_wrap(const SizedBox()));
  expect(controller.isDisposed, isFalse);
  controller.dispose();
  expect(controller.isDisposed, isTrue);
}

Map<String, Rect> _rects(WidgetTester tester) {
  final rects = <String, Rect>{};
  for (final option in _options()) {
    rects[option.value] = tester.getRect(
      find.byKey(ValueKey<String>('filter_${option.label}')),
    );
  }
  return rects;
}

/// Explicit tolerance of the geometric assert (stable CI, POC lesson).
const double _tolerance = 0.5;

void _expectSameGeometry(Map<String, Rect> before, Map<String, Rect> after) {
  for (final key in before.keys) {
    expect(
      (after[key]!.width - before[key]!.width).abs(),
      lessThanOrEqualTo(_tolerance),
      reason: 'chip $key changed width on selection flip',
    );
    expect(
      (after[key]!.left - before[key]!.left).abs(),
      lessThanOrEqualTo(_tolerance),
      reason: 'chip $key moved on selection flip',
    );
  }
}

/// Naive chip that renders a conditional checkmark (the POC bug): selecting
/// it MUST shift the width, proving the geometric assert is not vacuous.
class _NaiveChipRow extends StatefulWidget {
  const _NaiveChipRow();

  @override
  State<_NaiveChipRow> createState() => _NaiveChipRowState();
}

class _NaiveChipRowState extends State<_NaiveChipRow> {
  var _selected = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: GestureDetector(
          key: const ValueKey<String>('naive_chip'),
          onTap: () => setState(() => _selected = !_selected),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Medium label'),
                if (_selected) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.check, size: 18),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  tearDown(() {
    final forgotten = <FilterPanelController<String>>[];
    final alive = <FilterPanelController<String>>[];
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

  group('UC-12.04 FilterPanel', () {
    testWidgets('selection flip keeps every chip rect identical (no reflow)', (
      tester,
    ) async {
      final controller = _controller();

      await tester.pumpWidget(_wrap(_panel(controller)));
      await tester.pumpAndSettle();
      final before = _rects(tester);

      await _tapChip(tester, 'A');
      await tester.pumpAndSettle();
      final after = _rects(tester);

      // Positivo: geometria estavel dentro da tolerancia explicita.
      _expectSameGeometry(before, after);
      // Negativos: o tap fez efeito real (sem isso o assert seria vacuo)
      // e os demais chips seguem nao selecionados.
      expect(controller.selected.value, <String>{'a'});
      expect(controller.selected.value, isNot(contains('b')));

      await _unmountAndDispose(tester, controller);
    });

    testWidgets('multi-select accumulates without reflow', (tester) async {
      final controller = _controller();

      await tester.pumpWidget(_wrap(_panel(controller)));
      await tester.pumpAndSettle();
      final before = _rects(tester);

      await _tapChip(tester, 'A');
      await tester.pumpAndSettle();
      await _tapChip(tester, 'Medium label');
      await tester.pumpAndSettle();
      final after = _rects(tester);

      // Positivo: acumulou sem reflow.
      expect(controller.selected.value, <String>{'a', 'b'});
      _expectSameGeometry(before, after);
      // Negativos: o terceiro chip nao entrou sozinho; desmarcar volta a um.
      await _tapChip(tester, 'A');
      await tester.pumpAndSettle();
      expect(controller.selected.value, <String>{'b'});
      expect(controller.selected.value, isNot(contains('c')));

      await _unmountAndDispose(tester, controller);
    });

    testWidgets(
      'single mode replaces the selection; callback delivers the set',
      (tester) async {
        final controller = _controller(multi: false);
        final delivered = <Set<String>>[];

        await tester.pumpWidget(
          _wrap(_panel(controller, onChanged: delivered.add)),
        );
        await tester.pumpAndSettle();

        await _tapChip(tester, 'A');
        await tester.pumpAndSettle();
        await _tapChip(tester, 'Medium label');
        await tester.pumpAndSettle();

        // Positivo: single troca e o callback entrega o conjunto vigente.
        expect(controller.selected.value, <String>{'b'});
        expect(delivered.last, <String>{'b'});
        // Negativos: o anterior saiu; o callback nao disparou sem interacao.
        expect(controller.selected.value, isNot(contains('a')));
        expect(delivered.length, 2);

        await _unmountAndDispose(tester, controller);
      },
    );

    testWidgets(
      'negative proof: conditional checkmark variant DOES shift width',
      (tester) async {
        await tester.pumpWidget(const _NaiveChipRow());
        await tester.pumpAndSettle();
        final before = tester.getRect(
          find.byKey(const ValueKey<String>('naive_chip')),
        );

        await tester.tap(find.byKey(const ValueKey<String>('naive_chip')));
        await tester.pumpAndSettle();
        final after = tester.getRect(
          find.byKey(const ValueKey<String>('naive_chip')),
        );

        // Positivo da prova negativa: a variante ingenua reflow de verdade,
        // logo o assert geometrico do FilterPanel seria capaz de reprovar.
        expect(
          (after.width - before.width).abs(),
          greaterThan(_tolerance),
          reason: 'naive chip should reflow (otherwise the proof is vacuous)',
        );
        // Negativo: a altura nao colapsou (so a largura moveu).
        expect(after.height, moreOrLessEquals(before.height, epsilon: 1.0));
      },
    );

    testWidgets(
      'unmount keeps the controller alive; use after dispose throws',
      (tester) async {
        final controller = _controller();

        await tester.pumpWidget(_wrap(_panel(controller)));
        await tester.pumpAndSettle();
        expect(find.text('A'), findsOneWidget);

        await tester.pumpWidget(_wrap(const SizedBox()));
        // Positivo: o dono segue vivo (o widget nunca dispoe o controller).
        expect(controller.isDisposed, isFalse);
        // Negativos: valores nao evaporam no unmount; toggle pos-dispose falha.
        expect(controller.selected.peek(), isEmpty);
        controller.dispose();
        expect(controller.isDisposed, isTrue);
        expect(() => controller.toggle('a'), throwsStateError);
      },
    );
  });
}

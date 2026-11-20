import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poc/app/visits_app.dart';

void main() {
  group('filtro de status (estabilidade visual)', () {
    testWidgets('chip nao se desloca ao filtrar (sem reflow)', (tester) async {
      await tester.pumpWidget(createVisitsApp());
      await tester.pump(const Duration(seconds: 3));

      final chip = find.byKey(const Key('visits-filter-scheduled'));
      final initial = tester.getRect(chip);

      await tester.tap(chip);

      // A troca de filtro passa pelo estado de carregamento: a posicao
      // precisa permanecer identica em todos os frames.
      for (final ms in [16, 100, 200, 400]) {
        await tester.pump(Duration(milliseconds: ms));
        expect(tester.getRect(chip), initial, reason: 'chip deslocou em T+$ms');
      }
    });
  });
}

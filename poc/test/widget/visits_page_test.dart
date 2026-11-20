import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex/kortex.dart';
import 'package:poc/app/visits_app.dart';
import 'package:poc/modules/visits/data/.index.dart';

void main() {
  group('VisitsPage', () {
    testWidgets('abre com carregamento e depois lista vazia', (tester) async {
      await tester.pumpWidget(createVisitsApp());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Nenhuma visita'), findsOneWidget);
    });

    testWidgets('dialog herda o escopo via capture e agenda visita', (
      tester,
    ) async {
      await tester.pumpWidget(createVisitsApp());
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.byKey(const Key('visits-new')));
      await tester.pumpAndSettle();

      expect(find.text('Nova visita'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('new-visit-title')),
        'Troca do roteador',
      );
      await tester.ensureVisible(find.byKey(const Key('new-visit-save')));
      await tester.tap(find.byKey(const Key('new-visit-save')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.text('Nova visita'), findsNothing);
      expect(find.text('Troca do roteador'), findsOneWidget);
    });

    testWidgets('inicia e conclui a visita pela lista', (tester) async {
      await tester.pumpWidget(createVisitsApp());
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.byKey(const Key('visits-new')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('new-visit-title')), 'Troca');
      await tester.ensureVisible(find.byKey(const Key('new-visit-save')));
      await tester.tap(find.byKey(const Key('new-visit-save')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('visit-start-1')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byKey(const Key('visit-complete-1')), findsOneWidget);

      await tester.tap(find.byKey(const Key('visit-complete-1')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('filtro por status esconde visitas de outro status', (
      tester,
    ) async {
      await tester.pumpWidget(createVisitsApp());
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.byKey(const Key('visits-new')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('new-visit-title')), 'Troca');
      await tester.ensureVisible(find.byKey(const Key('new-visit-save')));
      await tester.tap(find.byKey(const Key('new-visit-save')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('visits-filter-completed')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Troca'), findsNothing);
      expect(find.text('Nenhuma visita'), findsOneWidget);
    });

    testWidgets('falha de infraestrutura mostra retry e recupera', (
      tester,
    ) async {
      final failing = InMemoryVisitStore(latency: Duration.zero)
        ..failNext = true;
      await tester.pumpWidget(
        createVisitsApp(
          overrides: [KortexProvider<InMemoryVisitStore>.value(value: failing)],
        ),
      );
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Falha ao carregar as visitas'), findsOneWidget);

      await tester.tap(find.byKey(const Key('visits-retry')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Nenhuma visita'), findsOneWidget);
    });
  });
}

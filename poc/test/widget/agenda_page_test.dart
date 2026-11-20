import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poc/app/visits_app.dart';

void main() {
  group('AgendaPage', () {
    testWidgets('mostra o dia selecionado e o estado vazio', (tester) async {
      await tester.pumpWidget(createVisitsApp(seedDemo: false));
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.text('Agenda'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Agenda'), findsWidgets);
      expect(find.text('Nenhuma visita neste dia'), findsOneWidget);
    });

    testWidgets('agenda mostra so a visita do dia agendado', (tester) async {
      await tester.pumpWidget(createVisitsApp());
      await tester.pump(const Duration(seconds: 2));

      // Agenda uma visita (o controller usa amanha quando nao ha data).
      await tester.tap(find.byKey(const Key('visits-new')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('new-visit-title')),
        'Visita de amanha',
      );
      await tester.tap(find.byKey(const Key('new-visit-save')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Agenda'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      // Hoje nao deve ter a visita agendada para amanha.
      expect(find.text('Visita de amanha'), findsNothing);
      expect(find.text('Nenhuma visita neste dia'), findsOneWidget);

      // O chip do dia seguinte (offset 1) mostra a visita.
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      await tester.tap(find.byKey(Key('agenda-day-${tomorrow.day}')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Visita de amanha'), findsOneWidget);
    });

    testWidgets('navegacao entre areas preserva o estado', (tester) async {
      await tester.pumpWidget(createVisitsApp());
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.text('Clientes'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      // O seed cria o cliente de demonstracao e ele persiste ao voltar.
      expect(find.text('Cliente Demo'), findsOneWidget);

      await tester.tap(find.text('Visitas'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.tap(find.text('Clientes'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Cliente Demo'), findsOneWidget);
    });
  });
}

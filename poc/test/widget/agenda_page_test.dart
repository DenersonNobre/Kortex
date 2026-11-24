import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poc/app/visits_app.dart';

void main() {
  group('AgendaPage', () {
    testWidgets('mostra cards do mes e vira para o detalhe do dia vazio', (
      tester,
    ) async {
      await tester.pumpWidget(createVisitsApp(seedDemo: false));
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.text('Agenda'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      final today = DateTime.now();
      final todayCard = find.byKey(Key('agenda-day-${today.day}'));
      expect(todayCard, findsOneWidget);

      await tester.drag(find.byType(GridView), const Offset(0, -200));
      await tester.pumpAndSettle();
      await tester.tap(todayCard);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Nenhuma visita neste dia'), findsOneWidget);

      await tester.tap(find.byKey(const Key('agenda-back')));
      await tester.pumpAndSettle();
      expect(find.byKey(Key('agenda-day-${today.day}')), findsOneWidget);
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

      // Toca no card de hoje: nao deve ter a visita agendada para amanha.
      final today = DateTime.now();
      final todayCard = find.byKey(Key('agenda-day-${today.day}'));
      await tester.drag(find.byType(GridView), const Offset(0, -200));
      await tester.pumpAndSettle();
      await tester.tap(todayCard);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Visita de amanha'), findsNothing);
      expect(find.text('Nenhuma visita neste dia'), findsOneWidget);

      // Volta para o mes e toca no card de amanha.
      await tester.tap(find.byKey(const Key('agenda-back')));
      await tester.pumpAndSettle();

      final tomorrow = today.add(const Duration(days: 1));
      if (tomorrow.month != today.month) {
        await tester.tap(find.byKey(const Key('agenda-next-month')));
        await tester.pumpAndSettle();
      }
      final tomorrowCard = find.byKey(Key('agenda-day-${tomorrow.day}'));
      await tester.drag(find.byType(GridView), const Offset(0, -200));
      await tester.pumpAndSettle();
      await tester.tap(tomorrowCard);
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

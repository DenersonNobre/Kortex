import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex_lib/core/core.dart';
import 'package:kortex_lib/widgets/widgets.dart';

void main() {
  group('ObservableAdapter', () {
    test('expõe o valor corrente do Observable', () {
      final observable = Observable<int>(3);

      expect(observable.asListenable().value, 3);
    });

    test('propaga mudança de valor para o ValueListenable', () {
      final observed = <int>[];
      final observable = Observable<int>(0);
      observable.asListenable().addListener(
        () => observed.add(observable.value),
      );
      observable.value = 4;

      expect(observed, [4]);
    });

    test('cancela assinatura pelo adaptador', () {
      var notified = 0;
      void listener() => notified++;
      final observable = Observable<int>(0);
      final listenable = observable.asListenable();

      listenable.addListener(listener);
      observable.value = 1;
      listenable.removeListener(listener);
      observable.value = 2;

      expect(notified, 1);
      expect(observable.value, 2);
    });
  });

  group('Command integrado aos widgets', () {
    testWidgets('NotifierBuilder reflete o resultado do Command', (
      tester,
    ) async {
      final command = Command<int, String, int>(
        (param) async => Success(param! * 2),
        mapException: (_, _) => 'erro',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotifierBuilder<IResult<int, String>?>(
              listenable: command.result.asListenable(),
              builder: (_, result) => Text('${result?.getOrNull() ?? 0}'),
            ),
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);

      await command.run(21);
      await tester.pump();

      expect(find.text('42'), findsOneWidget);
      command.dispose();
    });

    testWidgets('AsyncButton exibe loading enquanto o Command executa', (
      tester,
    ) async {
      final completude = Completer<IResult<int, String>>();
      final command = Command<int, String, void>(
        (_) => completude.future,
        mapException: (_, _) => 'erro',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsyncButton(
              loading: command.isExecuting.asListenable(),
              onPressed: command.run,
              child: const Text('Enviar'),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsNothing);

      final emCurso = command.run();
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completude.complete(Success(1));
      await emCurso;
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      command.dispose();
    });
  });
}

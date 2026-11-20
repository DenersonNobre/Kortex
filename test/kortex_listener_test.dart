import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex/src/reactive/reactive.dart';
import 'package:kortex/src/widgets/widgets.dart';

void main() {
  group('KortexListener', () {
    testWidgets('não dispara na montagem com fireImmediately false', (
      tester,
    ) async {
      final signal = KortexSignal(1);
      final calls = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: KortexListener<int>(
            watch: () => signal.value,
            listener: (context, value) => calls.add(value),
            child: const SizedBox(),
          ),
        ),
      );
      expect(calls, isEmpty);

      signal.value = 2;
      await tester.pump();

      expect(calls, [2]);
    });

    testWidgets('fireImmediately dispara logo após montar', (tester) async {
      final signal = KortexSignal(1);
      final calls = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: KortexListener<int>(
            watch: () => signal.value,
            listener: (context, value) => calls.add(value),
            fireImmediately: true,
            child: const SizedBox(),
          ),
        ),
      );
      await tester.pump();

      expect(calls, [1]);

      signal.value = 2;
      await tester.pump();
      expect(calls, [1, 2]);
    });

    testWidgets('só dispara quando o derivado muda', (tester) async {
      final signal = KortexSignal(5);
      final calls = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: KortexListener<int>(
            watch: () => signal.value ~/ 10,
            listener: (context, value) => calls.add(value),
            child: const SizedBox(),
          ),
        ),
      );

      signal.value = 9;
      await tester.pump();
      expect(calls, isEmpty);

      signal.value = 15;
      await tester.pump();
      expect(calls, [1]);
    });

    testWidgets('mudança durante o build executa fora da fase de build', (
      tester,
    ) async {
      final signal = KortexSignal(0);
      var armed = false;
      late StateSetter setOuter;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                setOuter = setState;
                if (armed) {
                  armed = false;
                  signal.value = 1;
                }
                return KortexListener<int>(
                  watch: () => signal.value,
                  listener: (listenerContext, value) {
                    ScaffoldMessenger.of(listenerContext)
                        .showSnackBar(SnackBar(content: Text('v$value')));
                  },
                  child: const SizedBox(),
                );
              },
            ),
          ),
        ),
      );

      armed = true;
      setOuter(() {});
      await tester.pump();
      await tester.pump();

      expect(find.text('v1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('não dispara após unmount', (tester) async {
      final signal = KortexSignal(1);
      final calls = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: KortexListener<int>(
            watch: () => signal.value,
            listener: (context, value) => calls.add(value),
            child: const SizedBox(),
          ),
        ),
      );
      await tester.pumpWidget(const SizedBox());

      signal.value = 2;
      await tester.pump();

      expect(calls, isEmpty);
      expect(tester.takeException(), isNull);
    });
  });

  group('KortexResourceBuilder', () {
    testWidgets('renderiza loading, data e error', (tester) async {
      final gate = Completer<String>();
      final resource = KortexResource<String>(() => gate.future);

      await tester.pumpWidget(
        MaterialApp(
          home: KortexResourceBuilder<String>(
            resource: resource,
            loading: (context) => const Text('loading'),
            error: (context, error, stackTrace) => const Text('error'),
            data: (context, value) => Text('data:$value'),
          ),
        ),
      );
      expect(find.text('loading'), findsOneWidget);

      gate.complete('ok');
      await tester.pump();

      expect(find.text('data:ok'), findsOneWidget);
      resource.dispose();
    });

    testWidgets('erro com retentativa recupera', (tester) async {
      var calls = 0;
      final resource = KortexResource<String>(
        () => ++calls == 1
            ? Future<String>.error(StateError('boom'))
            : Future.value('ok'),
        immediate: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: KortexResourceBuilder<String>(
            resource: resource,
            loading: (context) => const Text('loading'),
            error: (context, error, stackTrace) => TextButton(
              onPressed: () => resource.refresh(),
              child: const Text('retry'),
            ),
            data: (context, value) => Text('data:$value'),
          ),
        ),
      );
      await resource.refresh();
      await tester.pump();
      expect(find.text('retry'), findsOneWidget);

      await tester.tap(find.text('retry'));
      await tester.pump();

      expect(find.text('data:ok'), findsOneWidget);
      resource.dispose();
    });

    testWidgets('preserva previousValue visível durante refresh', (
      tester,
    ) async {
      final second = Completer<String>();
      var calls = 0;
      final resource = KortexResource<String>(
        () => ++calls == 1 ? Future.value('v1') : second.future,
        immediate: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: KortexResourceBuilder<String>(
            resource: resource,
            loading: (context) => const Text('loading'),
            error: (context, error, stackTrace) => const Text('error'),
            data: (context, value) => Text('data:$value'),
          ),
        ),
      );
      await resource.refresh();
      await tester.pump();
      expect(find.text('data:v1'), findsOneWidget);

      final pending = resource.refresh();
      await tester.pump();
      expect(find.text('loading'), findsOneWidget);

      second.complete('v2');
      await pending;
      await tester.pump();
      expect(find.text('data:v2'), findsOneWidget);
      resource.dispose();
    });
  });
}

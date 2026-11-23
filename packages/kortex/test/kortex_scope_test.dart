import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex/src/reactive/reactive.dart';
import 'package:kortex/src/scope/scope.dart';

/// Serviço simples com contador de fábrica.
class ServiceA {
  ServiceA([this.tag = 'a']);

  final String tag;
}

/// Serviço que depende de [ServiceA] via irmãos.
class ServiceB {
  ServiceB(this.a);

  final ServiceA a;
}

/// Tipo ausente de propósito (erro `INV-03`).
class _Absent {}

/// Descartável com marcador de tipo (um registro por `Type` no escopo).
class TaggedDisposable<T extends Object> implements IKortexDisposable {
  TaggedDisposable(this.name, this.log);

  final String name;
  final List<String> log;

  @override
  void dispose() => log.add(name);
}

void main() {
  group('KortexScope', () {
    testWidgets('resolve irmãos fora de ordem, criando B depois de A', (
      tester,
    ) async {
      var creationsA = 0;
      var creationsB = 0;
      final providers = <KortexProvider<dynamic>>[
        KortexProvider<ServiceB>(
          create: (scope) {
            creationsB++;
            return ServiceB(scope.read<ServiceA>());
          },
        ),
        KortexProvider<ServiceA>(
          create: (_) {
            creationsA++;
            return ServiceA();
          },
          lazy: true,
        ),
      ];
      ServiceB? seen;

      await tester.pumpWidget(
        KortexScope(
          providers: providers,
          child: Builder(
            builder: (context) {
              seen = context.readKortex<ServiceB>();
              return const SizedBox();
            },
          ),
        ),
      );

      expect(creationsA, 1);
      expect(creationsB, 1);
      expect(seen?.a, isA<ServiceA>());
    });

    testWidgets('lazy não cria até o primeiro read', (tester) async {
      var calls = 0;
      final providers = <KortexProvider<dynamic>>[
        KortexProvider<ServiceA>(
          create: (_) {
            calls++;
            return ServiceA();
          },
          lazy: true,
        ),
      ];

      await tester.pumpWidget(
        KortexScope(providers: providers, child: const SizedBox()),
      );
      expect(calls, 0);

      await tester.pumpWidget(
        KortexScope(
          providers: providers,
          child: Builder(
            builder: (context) {
              context.readKortex<ServiceA>();
              return const SizedBox();
            },
          ),
        ),
      );
      expect(calls, 1);
    });

    testWidgets('ciclo entre irmãos lança StateError descritivo', (
      tester,
    ) async {
      final providers = <KortexProvider<dynamic>>[
        KortexProvider<ServiceA>(
          create: (scope) => ServiceA(scope.read<ServiceB>().a.tag),
        ),
        KortexProvider<ServiceB>(
          create: (scope) => ServiceB(scope.read<ServiceA>()),
        ),
      ];

      await tester.pumpWidget(
        KortexScope(providers: providers, child: const SizedBox()),
      );

      final error = tester.takeException();
      expect(error, isStateError);
      expect(error.toString(), contains('circular'));
    });

    testWidgets('tipo ausente lança StateError com o tipo', (tester) async {
      await tester.pumpWidget(
        KortexScope(
          providers: const [],
          child: Builder(
            builder: (context) {
              context.readKortex<_Absent>();
              return const SizedBox();
            },
          ),
        ),
      );

      final error = tester.takeException();
      expect(error, isStateError);
      expect(error.toString(), contains('_Absent'));
    });

    testWidgets('desmontar descarta em LIFO e preserva .value', (tester) async {
      final log = <String>[];
      final external = Object();
      final providers = <KortexProvider<dynamic>>[
        KortexProvider<TaggedDisposable<ServiceA>>(
          create: (_) => TaggedDisposable<ServiceA>('a', log),
        ),
        KortexProvider<TaggedDisposable<ServiceB>>(
          create: (_) => TaggedDisposable<ServiceB>('b', log),
        ),
        KortexProvider<Object>.value(value: external),
      ];

      await tester.pumpWidget(
        KortexScope(providers: providers, child: const SizedBox()),
      );
      await tester.pumpWidget(const SizedBox());

      expect(log, ['b', 'a']);
    });

    testWidgets('dispose explícito vence o auto-dispose tipado', (
      tester,
    ) async {
      final log = <String>[];
      final providers = <KortexProvider<dynamic>>[
        KortexProvider<TaggedDisposable<ServiceA>>(
          create: (_) => TaggedDisposable<ServiceA>('a', log),
          dispose: (instance) => log.add('custom-${instance.name}'),
        ),
      ];

      await tester.pumpWidget(
        KortexScope(providers: providers, child: const SizedBox()),
      );
      await tester.pumpWidget(const SizedBox());

      expect(log, ['custom-a']);
    });

    testWidgets('preserva instâncias em rebuilds do pai', (tester) async {
      var calls = 0;
      final providers = <KortexProvider<dynamic>>[
        KortexProvider<ServiceA>(
          create: (_) {
            calls++;
            return ServiceA();
          },
        ),
      ];
      final seen = <ServiceA>[];
      late StateSetter setOuter;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              setOuter = setState;
              return KortexScope(
                providers: providers,
                child: Builder(
                  builder: (context) {
                    seen.add(context.readKortex<ServiceA>());
                    return const SizedBox();
                  },
                ),
              );
            },
          ),
        ),
      );
      setOuter(() {});
      await tester.pump();

      expect(calls, 1);
      expect(seen.length, 2);
      expect(identical(seen[0], seen[1]), isTrue);
    });

    testWidgets('providers novos descartam antigos e recriam', (tester) async {
      final log = <String>[];
      KortexProvider<ServiceA> make(String tag) => KortexProvider<ServiceA>(
        create: (_) {
          log.add('create-$tag');
          return ServiceA(tag);
        },
        dispose: (instance) => log.add('dispose-${instance.tag}'),
      );

      await tester.pumpWidget(
        KortexScope(providers: [make('v1')], child: const SizedBox()),
      );
      await tester.pumpWidget(
        KortexScope(providers: [make('v2')], child: const SizedBox()),
      );

      expect(log, ['create-v1', 'dispose-v1', 'create-v2']);
    });

    testWidgets('watch reconstrói quando o escopo atualiza', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: KortexScope(
            providers: [KortexProvider<String>.value(value: 'v1')],
            child: Builder(
              builder: (context) => Text(
                context.watchKortex<String>(),
                textDirection: TextDirection.ltr,
              ),
            ),
          ),
        ),
      );
      expect(find.text('v1'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: KortexScope(
            providers: [KortexProvider<String>.value(value: 'v2')],
            child: Builder(
              builder: (context) => Text(
                context.watchKortex<String>(),
                textDirection: TextDirection.ltr,
              ),
            ),
          ),
        ),
      );
      expect(find.text('v2'), findsOneWidget);
    });
  });
}

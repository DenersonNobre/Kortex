import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex/src/reactive/reactive.dart';
import 'package:kortex/src/scope/scope.dart';

/// Repositório real (produção).
class Repo {
  String get name => 'real';
}

/// Fake para `overrides` em testes.
class FakeRepo extends Repo {
  @override
  String get name => 'fake';
}

/// Controller descartável do cenário de `capture`.
class Ctrl implements IKortexDisposable {
  var disposed = false;

  @override
  void dispose() => disposed = true;
}

/// Serviço simples para resolução em árvore.
class ServiceA {
  ServiceA([this.tag = 'a']);

  final String tag;
}

void main() {
  group('KortexScope (árvore, capture e overrides)', () {
    testWidgets('overrides substitui o provider real', (tester) async {
      var realCalls = 0;
      String? seen;

      await tester.pumpWidget(
        KortexScope(
          providers: [
            KortexProvider<Repo>(
              create: (_) {
                realCalls++;
                return Repo();
              },
            ),
          ],
          overrides: [KortexProvider<Repo>.value(value: FakeRepo())],
          child: Builder(
            builder: (context) {
              seen = context.readKortex<Repo>().name;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(seen, 'fake');
      expect(realCalls, 0);
    });

    testWidgets('escopo interno sombreia o externo', (tester) async {
      String? seen;

      await tester.pumpWidget(
        KortexScope(
          providers: [KortexProvider<ServiceA>.value(value: ServiceA('outer'))],
          child: KortexScope(
            providers: [
              KortexProvider<ServiceA>.value(value: ServiceA('inner')),
            ],
            child: Builder(
              builder: (context) {
                seen = context.readKortex<ServiceA>().tag;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(seen, 'inner');
    });

    testWidgets('tipo ausente no interno resolve no ancestral', (tester) async {
      ServiceA? outer;
      ServiceA? inner;

      await tester.pumpWidget(
        KortexScope(
          providers: [KortexProvider<ServiceA>.value(value: ServiceA('outer'))],
          child: Builder(
            builder: (outerContext) {
              outer = outerContext.readKortex<ServiceA>();
              return KortexScope(
                providers: const [],
                child: Builder(
                  builder: (innerContext) {
                    inner = innerContext.readKortex<ServiceA>();
                    return const SizedBox();
                  },
                ),
              );
            },
          ),
        ),
      );

      expect(identical(inner, outer), isTrue);
    });

    testWidgets('capture expõe o escopo no dialog sem transferir posse', (
      tester,
    ) async {
      var calls = 0;
      Ctrl? rootSeen;
      Ctrl? dialogSeen;
      BuildContext? dialogContext;

      await tester.pumpWidget(
        MaterialApp(
          home: KortexScope(
            providers: [
              KortexProvider<Ctrl>(
                create: (_) {
                  calls++;
                  return Ctrl();
                },
              ),
            ],
            child: Builder(
              builder: (outerContext) {
                rootSeen = outerContext.readKortex<Ctrl>();
                return TextButton(
                  onPressed: () {
                    showDialog<void>(
                      context: outerContext,
                      builder: (_) => KortexScope.capture(
                        context: outerContext,
                        child: Builder(
                          builder: (dialogCtx) {
                            dialogContext = dialogCtx;
                            dialogSeen = dialogCtx.readKortex<Ctrl>();
                            return const Text('dialog-ok');
                          },
                        ),
                      ),
                    );
                  },
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      );
      expect(calls, 1);

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('dialog-ok'), findsOneWidget);
      expect(identical(dialogSeen, rootSeen), isTrue);

      Navigator.of(dialogContext!).pop();
      await tester.pumpAndSettle();

      expect(find.text('dialog-ok'), findsNothing);
      expect(rootSeen?.disposed, isFalse);
    });

    testWidgets('capture não vaza lazy não materializado', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: KortexScope(
            providers: [
              KortexProvider<ServiceA>(create: (_) => ServiceA(), lazy: true),
            ],
            child: Builder(
              builder: (outerContext) {
                return TextButton(
                  onPressed: () {
                    showDialog<void>(
                      context: outerContext,
                      builder: (_) => KortexScope.capture(
                        context: outerContext,
                        child: Builder(
                          builder: (dialogContext) {
                            dialogContext.readKortex<ServiceA>();
                            return const SizedBox();
                          },
                        ),
                      ),
                    );
                  },
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final error = tester.takeException();
      expect(error, isStateError);
    });

    testWidgets('sem ancestral, read indica o tipo ausente', (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            context.readKortex<Ctrl>();
            return const SizedBox();
          },
        ),
      );

      final error = tester.takeException();
      expect(error, isStateError);
      expect(error.toString(), contains('Ctrl'));
    });
  });
}

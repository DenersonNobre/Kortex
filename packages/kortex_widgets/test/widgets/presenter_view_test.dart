// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex/kortex.dart';
import 'package:kortex_widgets/src/widgets/presenter_view.dart';

class _FakePresenter extends IKortexController {
  final String title = 'Canônico';
  int counter = 0;
  void increment() => counter++;
}

class _TestView extends PresenterView<_FakePresenter> {
  const _TestView();

  _FakePresenter get exposePresenterForTest => presenter;

  @override
  Widget buildWithPresenter(BuildContext context, _FakePresenter presenter) {
    return Column(
      children: [
        Text(this.presenter.title),
        ElevatedButton(
          onPressed: _onButtonPressed,
          child: const Text('Incrementar'),
        ),
      ],
    );
  }

  void _onButtonPressed() {
    presenter.increment();
  }
}

/// Presenters owned by the running test.
///
/// Inline version of the `track`/`expectAllTrackedDisposed` gate from the
/// `kortex` package: `kortex_widgets` has no leak infra, so each test
/// registers the presenters it creates and the `tearDown` in `main` fails
/// the test when any of them stays alive.
final List<_FakePresenter> _openPresenters = [];

_FakePresenter _trackPresenter(_FakePresenter presenter) {
  _openPresenters.add(presenter);
  return presenter;
}

void _disposePresenter(_FakePresenter presenter) {
  if (presenter.isDisposed) {
    return;
  }
  presenter.dispose();
}

void main() {
  tearDown(() {
    final alive = <_FakePresenter>[];
    for (final presenter in _openPresenters) {
      _disposePresenter(presenter);
      if (!presenter.isDisposed) {
        alive.add(presenter);
      }
    }
    _openPresenters.clear();
    expect(alive, isEmpty, reason: 'Presenters nao descartados: $alive');
  });

  group('PresenterView com getter presenter direto na dnolib', () {
    testWidgets('permite acessar presenter via getter dentro e fora do build', (
      tester,
    ) async {
      final fake = _trackPresenter(_FakePresenter());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PresenterScope<_FakePresenter>(
              presenter: fake,
              child: const _TestView(),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Canônico'), findsOneWidget);
      expect(fake.counter, 0);

      await tester.tap(find.text('Incrementar'));
      await tester.pump();

      expect(fake.counter, 1);

      fake.dispose();
      expect(fake.isDisposed, isTrue);
    });

    test(
      'lança StateError se getter presenter for lido antes de montar na árvore',
      () {
        const unmountedView = _TestView();
        expect(
          () => unmountedView.exposePresenterForTest,
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains(
                'Não é possível acessar o getter "presenter" antes da montagem',
              ),
            ),
          ),
        );
      },
    );
  });

  group('UC-12.00 unificacao de escopo (KortexScope)', () {
    testWidgets(
      'KortexProvider.value + readKortex devolvem a mesma instancia que PresenterScope.of',
      (tester) async {
        final presenter = _trackPresenter(_FakePresenter());
        _FakePresenter? viaKortex;
        _FakePresenter? viaLegacy;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: KortexScope(
                providers: [
                  KortexProvider<_FakePresenter>.value(value: presenter),
                ],
                child: PresenterScope<_FakePresenter>(
                  presenter: presenter,
                  child: Builder(
                    builder: (context) {
                      viaKortex = context.readKortex<_FakePresenter>();
                      viaLegacy = PresenterScope.of<_FakePresenter>(context);
                      return Text(viaLegacy!.title);
                    },
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Canônico'), findsOneWidget);
        expect(viaLegacy, same(presenter));
        expect(viaKortex, same(presenter));
        expect(viaKortex, same(viaLegacy));
        expect(presenter.isDisposed, isFalse);

        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SizedBox())),
        );

        // `.value` keeps external ownership: unmount must NOT dispose it.
        expect(presenter.isDisposed, isFalse);

        presenter.dispose();
        expect(presenter.isDisposed, isTrue);
      },
    );

    testWidgets('KortexScope descarta a instancia propria ao desmontar', (
      tester,
    ) async {
      final presenter = _trackPresenter(_FakePresenter());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KortexScope(
              providers: [
                KortexProvider<_FakePresenter>(create: (_) => presenter),
              ],
              child: Builder(
                builder: (context) {
                  return Text(context.readKortex<_FakePresenter>().title);
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Canônico'), findsOneWidget);
      expect(presenter.isDisposed, isFalse);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );

      expect(presenter.isDisposed, isTrue);
    });

    testWidgets('PresenterScope removido nao resolve mais (pos-unmount)', (
      tester,
    ) async {
      final presenter = _trackPresenter(_FakePresenter());
      late BuildContext captured;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PresenterScope<_FakePresenter>(
              presenter: presenter,
              child: Builder(
                builder: (context) {
                  captured = context;
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );

      expect(PresenterScope.of<_FakePresenter>(captured), same(presenter));

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );

      expect(
        () => PresenterScope.of<_FakePresenter>(captured),
        throwsA(isA<FlutterError>()),
      );

      presenter.dispose();
      expect(presenter.isDisposed, isTrue);
    });

    testWidgets('readKortex fora de KortexScope lanca StateError', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                expect(
                  () => context.readKortex<_FakePresenter>(),
                  throwsA(isA<StateError>()),
                );
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('PresenterScope.of sem ancestral lanca StateError', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                expect(
                  () => PresenterScope.of<_FakePresenter>(context),
                  throwsA(isA<StateError>()),
                );
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });
  });
}


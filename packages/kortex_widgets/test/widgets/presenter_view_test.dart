import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex_widgets/src/widgets/presenter_view.dart';

class _FakePresenter {
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

void main() {
  group('PresenterView com getter presenter direto na dnolib', () {
    testWidgets('permite acessar presenter via getter dentro e fora do build', (
      tester,
    ) async {
      final fake = _FakePresenter();

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
}

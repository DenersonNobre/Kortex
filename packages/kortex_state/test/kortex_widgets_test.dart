import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex/src/reactive/reactive.dart';
import 'package:kortex/src/scope/scope.dart';
import 'package:kortex/src/widgets/widgets.dart';

/// Controller simples com sinais de nome e idade.
class UserController extends IKortexController {
  UserController() {
    name = autoDispose(KortexSignal('ana'));
    age = autoDispose(KortexSignal(30));
  }

  late final KortexSignal<String> name;
  late final KortexSignal<int> age;
}

/// Página de teste: resolve o controller via escopo.
class UserPage extends IKortexPage<UserController> {
  const UserPage({super.key});

  static UserController? seen;

  @override
  Widget buildPage(BuildContext context, UserController controller) {
    seen = controller;
    return Text(controller.name.value, textDirection: TextDirection.ltr);
  }
}

void main() {
  group('IKortexPage', () {
    testWidgets('resolve o controller via BuildContext', (tester) async {
      UserController? created;
      await tester.pumpWidget(
        MaterialApp(
          home: KortexScope(
            providers: [
              KortexProvider<UserController>(
                create: (_) {
                  created = UserController();
                  return created!;
                },
              ),
            ],
            child: const UserPage(),
          ),
        ),
      );

      expect(find.text('ana'), findsOneWidget);
      expect(identical(UserPage.seen, created), isTrue);
    });

    testWidgets('sem escopo lança StateError', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: UserPage()));

      final error = tester.takeException();
      expect(error, isStateError);
    });
  });

  group('KortexWatch', () {
    testWidgets('reconstrói preservando o child estático', (tester) async {
      final signal = KortexSignal(1);
      const childWidget = SizedBox(key: ValueKey('child'));
      var builds = 0;
      Widget? seenChild;

      await tester.pumpWidget(
        MaterialApp(
          home: KortexWatch(
            builder: (context, child) {
              builds++;
              seenChild = child;
              return Text('${signal.value}', textDirection: TextDirection.ltr);
            },
            child: childWidget,
          ),
        ),
      );
      expect(builds, 1);
      expect(find.text('1'), findsOneWidget);

      signal.value = 2;
      await tester.pump();

      expect(builds, 2);
      expect(find.text('2'), findsOneWidget);
      expect(identical(seenChild, childWidget), isTrue);
    });

    testWidgets('não chama setState após unmount', (tester) async {
      final signal = KortexSignal(1);

      await tester.pumpWidget(
        MaterialApp(
          home: KortexWatch(
            builder: (context, child) =>
                Text('${signal.value}', textDirection: TextDirection.ltr),
          ),
        ),
      );
      signal.value = 2;
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      signal.value = 3;
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('KortexSelector', () {
    testWidgets('só reconstrói quando a seleção muda', (tester) async {
      final name = KortexSignal('ana');
      final age = KortexSignal(30);
      var builds = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: KortexSelector<String>(
            selector: () => name.value,
            builder: (context, value, child) {
              builds++;
              return Text(value, textDirection: TextDirection.ltr);
            },
          ),
        ),
      );
      expect(builds, 1);

      age.value = 31;
      await tester.pump();
      expect(builds, 1);
      expect(find.text('ana'), findsOneWidget);

      name.value = 'bia';
      await tester.pump();
      expect(builds, 2);
      expect(find.text('bia'), findsOneWidget);
    });

    testWidgets('repassa o child estático intacto', (tester) async {
      final name = KortexSignal('ana');
      const childWidget = SizedBox(key: ValueKey('child'));
      Widget? seenChild;

      await tester.pumpWidget(
        MaterialApp(
          home: KortexSelector<String>(
            selector: () => name.value,
            builder: (context, value, child) {
              seenChild = child;
              return Text(value, textDirection: TextDirection.ltr);
            },
            child: childWidget,
          ),
        ),
      );

      name.value = 'bia';
      await tester.pump();

      expect(identical(seenChild, childWidget), isTrue);
    });
  });
}

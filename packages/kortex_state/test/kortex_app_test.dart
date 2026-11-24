import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex/kortex.dart';

class _Repository {
  const _Repository(this.value);
  final String value;
}

void main() {
  group('KortexMaterialApp', () {
    testWidgets(
      'provides injected dependencies and renders MaterialApp correctly',
      (tester) async {
        await tester.pumpWidget(
          KortexMaterialApp(
            providers: [
              KortexProvider<_Repository>(
                create: (_) => const _Repository('material_repo'),
              ),
            ],
            app: MaterialApp(
              title: 'Material Root Test',
              home: Builder(
                builder: (context) {
                  final repo = context.readKortex<_Repository>();
                  return Scaffold(
                    body: Text('Value: ${repo.value}'),
                  );
                },
              ),
            ),
          ),
        );

        expect(find.text('Value: material_repo'), findsOneWidget);
        final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
        expect(materialApp.title, equals('Material Root Test'));
      },
    );
  });

  group('KortexCupertinoApp', () {
    testWidgets(
      'provides injected dependencies and renders CupertinoApp correctly',
      (tester) async {
        await tester.pumpWidget(
          KortexCupertinoApp(
            providers: [
              KortexProvider<_Repository>(
                create: (_) => const _Repository('cupertino_repo'),
              ),
            ],
            app: CupertinoApp(
              title: 'Cupertino Root Test',
              home: Builder(
                builder: (context) {
                  final repo = context.readKortex<_Repository>();
                  return CupertinoPageScaffold(
                    navigationBar: const CupertinoNavigationBar(
                      middle: Text('Header'),
                    ),
                    child: Center(
                      child: Text('Value: ${repo.value}'),
                    ),
                  );
                },
              ),
            ),
          ),
        );

        expect(find.text('Value: cupertino_repo'), findsOneWidget);
        expect(find.text('Header'), findsOneWidget);
        final cupertinoApp =
            tester.widget<CupertinoApp>(find.byType(CupertinoApp));
        expect(cupertinoApp.title, equals('Cupertino Root Test'));
      },
    );
  });
}

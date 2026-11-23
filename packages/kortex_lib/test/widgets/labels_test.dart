import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex_lib/widgets/widgets.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('Caption exibe prefixo, texto e sufixo', (tester) async {
    await tester.pumpWidget(
      wrap(
        const Caption(
          prefix: Icon(Icons.info),
          text: Text('Legenda'),
          suffix: Icon(Icons.close),
        ),
      ),
    );

    expect(find.text('Legenda'), findsOneWidget);
    expect(find.byIcon(Icons.info), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets('Caption sem prefixo e sufixo renderiza apenas o texto', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(Caption(text: Text('So legenda'))));

    expect(find.text('So legenda'), findsOneWidget);
    expect(find.byType(Icon), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Label com texto vazio não renderiza texto', (tester) async {
    await tester.pumpWidget(wrap(Label(text: '')));

    expect(find.byType(Text), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Label aplica altura, alinhamento e cor ao texto', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(const Label(text: 'Titulo', color: Colors.red, height: 40)),
    );

    expect(find.text('Titulo'), findsOneWidget);
    expect(tester.getSize(find.byType(Label)).height, 40);
    final text = tester.widget<Text>(find.text('Titulo'));
    expect(text.style?.color, Colors.red);
    expect(text.maxLines, 1);
  });

  testWidgets('ShadedText aplica sombra, cor e tamanho de fonte', (
    tester,
  ) async {
    const shadow = Shadow(offset: Offset(1, 1), color: Colors.black);
    await tester.pumpWidget(
      wrap(
        const ShadedText(
          text: 'Sombra',
          fontSize: 18,
          color: Colors.white,
          shadow: shadow,
        ),
      ),
    );

    final text = tester.widget<Text>(find.text('Sombra'));
    expect(text.style?.fontSize, 18);
    expect(text.style?.color, Colors.white);
    expect(text.style?.shadows, const [shadow]);
  });

  testWidgets('ShadedText sem sombra deixa shadows nulo', (tester) async {
    await tester.pumpWidget(wrap(ShadedText(text: 'Liso')));

    final text = tester.widget<Text>(find.text('Liso'));
    expect(text.style?.shadows, isNull);
  });
}

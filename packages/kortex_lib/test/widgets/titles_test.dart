import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex_lib/widgets/widgets.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets(
    'SectionTitle renderiza titulo e subtitulo com o tamanho pedido',
    (
      tester,
    ) async {
      const title = 'Vendas';
      const subtitle = 'Fechamento do mes';

      await tester.pumpWidget(
        wrap(
          const SectionTitle(title: title, subtitle: subtitle, fontSize: 22),
        ),
      );

      final texts = tester.widgetList<Text>(find.byType(Text)).toList();
      expect(texts, hasLength(2));
      expect(texts[0].data, title);
      expect(texts[0].style?.fontSize, 22);
      expect(texts[1].data, subtitle);
      expect(
        texts[1].style,
        Theme.of(tester.element(find.text('Vendas'))).textTheme.bodySmall,
      );
    },
  );

  testWidgets('SectionTitle usa o estilo proprio quando informado', (
    tester,
  ) async {
    const custom = TextStyle(color: Colors.purple);

    await tester.pumpWidget(
      wrap(const SectionTitle(title: 'Painel', textStyle: custom)),
    );

    final texts = tester.widgetList<Text>(find.byType(Text)).toList();
    expect(texts, hasLength(1));
    expect(texts[0].style?.color, Colors.purple);
  });

  testWidgets('TitlePanel.text aplica cor, altura e alinhamento informados', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const TitlePanel.text(
          title: 'Cadastro',
          titleColor: Colors.white,
          backgroundColor: Colors.blueGrey,
          height: 80,
          padding: EdgeInsets.only(left: 24),
        ),
      ),
    );

    final container = tester.widget<Container>(find.byType(Container));
    expect(container.constraints?.maxHeight, 80);
    expect(container.color, Colors.blueGrey);
    expect(container.padding, const EdgeInsets.only(left: 24));
    expect(container.alignment, Alignment.centerLeft);

    final title = tester.widget<Text>(find.text('Cadastro'));
    expect(title.style?.color, Colors.white);
    expect(title.maxLines, 1);
  });

  testWidgets('TitlePanel exibe titulo e acoes na mesma linha', (tester) async {
    await tester.pumpWidget(
      wrap(
        const TitlePanel(
          title: Text('Painel de controle'),
          height: 60,
          backgroundColor: Colors.amber,
          padding: EdgeInsets.symmetric(horizontal: 8),
          margin: EdgeInsets.all(4),
          alignment: Alignment.center,
          actions: [Icon(Icons.add), Icon(Icons.remove)],
        ),
      ),
    );

    final container = tester.widget<Container>(find.byType(Container));
    expect(container.constraints?.maxHeight, 60);
    expect(container.color, Colors.amber);
    expect(container.margin, const EdgeInsets.all(4));
    expect(container.alignment, Alignment.center);

    expect(find.text('Painel de controle'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byIcon(Icons.remove), findsOneWidget);
  });
}

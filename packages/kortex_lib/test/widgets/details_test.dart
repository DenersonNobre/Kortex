import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex_lib/widgets/widgets.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets(
    'DetailItem vertical mescla estilo base com estilo de cada texto',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          const DetailItem(
            direction: Axis.vertical,
            style: TextStyle(fontSize: 20, color: Colors.blue),
            label: 'Rotulo',
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            value: 'Conteudo',
          ),
        ),
      );

      final texts = tester.widgetList<Text>(find.byType(Text)).toList();
      expect(texts, hasLength(2));
      expect(texts[0].data, 'Rotulo');
      expect(texts[0].style?.fontSize, 20);
      expect(texts[0].style?.fontWeight, FontWeight.bold);
      expect(texts[0].style?.color, Colors.blue);
      expect(texts[1].data, 'Conteudo');
      expect(texts[1].style?.fontSize, 20);
      expect(texts[1].style?.color, Colors.blue);
    },
  );

  testWidgets('DetailItem vertical omite rotulo ou valor nulo', (tester) async {
    await tester.pumpWidget(
      wrap(const DetailItem(direction: Axis.vertical, label: 'So rotulo')),
    );
    expect(find.text('So rotulo'), findsOneWidget);
    expect(find.byType(Text), findsOneWidget);

    await tester.pumpWidget(
      wrap(const DetailItem(direction: Axis.vertical, value: 'So conteudo')),
    );
    expect(find.text('So conteudo'), findsOneWidget);
    expect(find.byType(Text), findsOneWidget);
  });

  testWidgets('DetailItem pinta o fundo informado', (tester) async {
    await tester.pumpWidget(
      wrap(
        const DetailItem(
          direction: Axis.vertical,
          backgroundColor: Colors.yellow,
          value: 'Fundo',
        ),
      ),
    );

    final container = tester.widget<Container>(find.byType(Container));
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, Colors.yellow);
  });

  testWidgets(
    'DetailItem horizontal renderiza rotulo com largura fixa e valor',
    (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const DetailItem(
            label: 'Nome',
            value: 'Ana',
            labelSpace: 120,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
          ),
        ),
      );

      expect(find.text('Nome'), findsOneWidget);
      expect(find.text('Ana'), findsOneWidget);
      final sized = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(Flexible),
          matching: find.byType(SizedBox),
        ),
      );
      expect(sized.width, 120);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('DetailItem horizontal com valor nulo mantém linha estável', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const DetailItem(label: 'So rotulo')));

    expect(find.text('So rotulo'), findsOneWidget);
    expect(find.byType(SizedBox), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('DetailItem.keyValue mostra rotulo com dois-pontos e valor', (
    tester,
  ) async {
    late ThemeData capturedTheme;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            capturedTheme = Theme.of(context);
            return const Scaffold(
              body: DetailItem.keyValue(label: 'Cliente', value: 'Ana'),
            );
          },
        ),
      ),
    );

    expect(find.text('Cliente:'), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
    final label = tester.widget<Text>(find.text('Cliente:'));
    expect(label.style?.color, capturedTheme.colorScheme.onSurfaceVariant);
  });

  testWidgets('DetailItem.keyValue aplica estilos informados pelo chamador', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const DetailItem.keyValue(
          label: 'Cliente',
          value: 'Ana',
          labelStyle: TextStyle(color: Colors.purple),
          valueStyle: TextStyle(fontSize: 12),
        ),
      ),
    );

    final label = tester.widget<Text>(find.text('Cliente:'));
    final value = tester.widget<Text>(find.text('Ana'));
    expect(label.style?.color, Colors.purple);
    expect(value.style?.fontSize, 12);
  });
}

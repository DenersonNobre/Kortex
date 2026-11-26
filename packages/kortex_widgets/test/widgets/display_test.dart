import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex_widgets/kortex_widgets.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('StatusChip renderiza o icone opcional ao lado do texto', (
    tester,
  ) async {
    final label = 'Concluido';

    await tester.pumpWidget(
      wrap(
        StatusChip(
          text: label,
          backgroundColor: Colors.yellow,
          icon: Icons.check,
        ),
      ),
    );

    expect(find.text(label), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);

    final text = tester.widget<Text>(find.text(label));
    expect(text.style?.color, Colors.black87);
  });

  testWidgets('StatusChip usa branco em fundo escuro', (tester) async {
    await tester.pumpWidget(
      wrap(const StatusChip(text: 'Pendente', backgroundColor: Colors.black)),
    );

    final text = tester.widget<Text>(find.text('Pendente'));
    expect(text.style?.color, Colors.white);
  });

  testWidgets('SectionTitle mostra o subtitle abaixo do titulo', (
    tester,
  ) async {
    const title = 'Clientes';
    const subtitle = 'Atualizado agora';

    await tester.pumpWidget(
      wrap(const SectionTitle(title: title, subtitle: subtitle)),
    );

    expect(find.text(title), findsOneWidget);
    expect(find.text(subtitle), findsOneWidget);
  });

  testWidgets('ActionBar mapeia cada alinhamento para o Wrap correspondiente', (
    tester,
  ) async {
    final alignments = [
      MainAxisAlignment.center,
      MainAxisAlignment.spaceBetween,
      MainAxisAlignment.spaceAround,
      MainAxisAlignment.spaceEvenly,
    ];

    await tester.pumpWidget(
      wrap(
        Column(
          children: [
            for (final alignment in alignments)
              ActionBar(
                alignment: alignment,
                actions: [TextButton(onPressed: () {}, child: const Text('A'))],
              ),
          ],
        ),
      ),
    );

    final wraps = tester.widgetList<Wrap>(find.byType(Wrap)).toList();
    expect(wraps, hasLength(alignments.length));
    expect(wraps[0].alignment, WrapAlignment.center);
    expect(wraps[1].alignment, WrapAlignment.spaceBetween);
    expect(wraps[2].alignment, WrapAlignment.spaceAround);
    expect(wraps[3].alignment, WrapAlignment.spaceEvenly);
  });

  testWidgets('CardTile sem checkable aciona o onPressed do ListTile', (
    tester,
  ) async {
    var pressed = 0;
    await tester.pumpWidget(
      wrap(
        CardTile(title: const Text('Pedido 42'), onPressed: () => pressed++),
      ),
    );

    await tester.tap(find.text('Pedido 42'));
    expect(pressed, 1);
  });

  testWidgets('CardTile oculta o card quando invisivel', (tester) async {
    await tester.pumpWidget(
      wrap(const CardTile(title: Text('Segredo'), visible: false)),
    );

    expect(find.byType(Card), findsNothing);
    expect(find.text('Segredo'), findsNothing);
  });
}

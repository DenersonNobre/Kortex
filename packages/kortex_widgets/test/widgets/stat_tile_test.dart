import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex_widgets/kortex_widgets.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('StatTile renderiza valor e rotulo', (tester) async {
    await tester.pumpWidget(wrap(StatTile(value: '42', label: 'Vendas')));

    expect(find.text('42'), findsOneWidget);
    expect(find.text('Vendas'), findsOneWidget);
    expect(find.byType(Card), findsOneWidget);
  });

  testWidgets('StatTile sem ícone não exibe área de ícone', (tester) async {
    await tester.pumpWidget(wrap(const StatTile(value: '1', label: 'Total')));

    expect(find.byIcon(Icons.inventory_2_outlined), findsNothing);
    expect(find.byType(Icon), findsNothing);
  });

  testWidgets(
    'StatTile usa a cor primária do tema quando o ícone não informa cor',
    (tester) async {
      late ThemeData capturedTheme;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              capturedTheme = Theme.of(context);
              return const Scaffold(
                body: StatTile(
                  value: '7',
                  label: 'Pendencias',
                  icon: Icons.pending_actions_outlined,
                ),
              );
            },
          ),
        ),
      );

      final icon = tester.widget<Icon>(
        find.byIcon(Icons.pending_actions_outlined),
      );
      expect(icon.color, capturedTheme.colorScheme.primary);
    },
  );

  testWidgets('StatTile respeita a cor de ícone informada', (tester) async {
    await tester.pumpWidget(
      wrap(
        const StatTile(
          value: '9',
          label: 'Falhas',
          icon: Icons.error_outline,
          iconColor: Colors.orange,
        ),
      ),
    );

    final icon = tester.widget<Icon>(find.byIcon(Icons.error_outline));
    expect(icon.color, Colors.orange);
  });
}

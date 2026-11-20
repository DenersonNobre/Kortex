import 'package:example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('exemplo: contador, mensagem e salvamento', (tester) async {
    await tester.pumpWidget(createApp());

    expect(find.text('Cliques: 0'), findsOneWidget);

    await tester.tap(find.byTooltip('increment'));
    await tester.pump();
    expect(find.text('Cliques: 1'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Total: 42'), findsOneWidget);

    await tester.tap(find.text('Salvar'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('Salvo'), findsOneWidget);
  });
}

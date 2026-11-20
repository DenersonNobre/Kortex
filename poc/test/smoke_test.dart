import 'package:flutter_test/flutter_test.dart';
import 'package:poc/main.dart' as app;

void main() {
  testWidgets('entrada do app abre a tela de visitas', (tester) async {
    // Exercita o `main()` real do app (composição + seed de demonstração).
    app.main();
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    expect(find.text('Visitas técnicas'), findsOneWidget);
    expect(find.text('Nenhuma visita'), findsOneWidget);
  });
}
